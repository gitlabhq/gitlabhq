# frozen_string_literal: true

require 'parallel'

module QA
  RSpec.describe 'Create' do
    context 'Gitaly' do
      # Issue to track removal of feature flag: https://gitlab.com/gitlab-org/quality/team-tasks/-/issues/602
      describe 'Distributed reads', :orchestrated, :gitaly_ha, :skip_live_env, :requires_admin do
        let(:number_of_reads) { 100 }
        let(:praefect_manager) { Service::PraefectManager.new }
        let(:project) do
          Resource::Project.fabricate! do |project|
            project.name = "gitaly_cluster"
            project.initialize_with_readme = true
          end
        end

        before do
          Runtime::Feature.enable_and_verify('gitaly_distributed_reads')
          praefect_manager.wait_for_replication(project.id)
        end

        after do
          Runtime::Feature.disable_and_verify('gitaly_distributed_reads')
        end

        it 'reads from each node' do
          pre_read_data = praefect_manager.query_read_distribution

          QA::Runtime::Logger.info('Fetching commits from the repository')
          Parallel.each((1..number_of_reads)) { project.commits }

          praefect_manager.wait_for_read_count_change(pre_read_data)

          aggregate_failures "each gitaly node" do
            praefect_manager.query_read_distribution.each_with_index do |data, index|
              expect(data[:value])
                .to be > praefect_manager.value_for_node(pre_read_data, data[:node]),
                  "Read counts did not differ for node #{data[:node]}"
            end
          end
        end

        context 'when a node is unhealthy' do
          before do
            praefect_manager.stop_secondary_node
            praefect_manager.wait_for_secondary_node_health_check_failure
          end

          after do
            # Leave the cluster in a suitable state for subsequent tests
            praefect_manager.start_secondary_node
            praefect_manager.wait_for_health_check_all_nodes
            praefect_manager.wait_for_reliable_connection
          end

          it 'does not read from the unhealthy node' do
            pre_read_data = praefect_manager.query_read_distribution

            QA::Runtime::Logger.info('Fetching commits from the repository')
            Parallel.each((1..number_of_reads)) { project.commits }

            praefect_manager.wait_for_read_count_change(pre_read_data)

            post_read_data = praefect_manager.query_read_distribution

            aggregate_failures "each gitaly node" do
              expect(praefect_manager.value_for_node(post_read_data, 'gitaly1')).to be > praefect_manager.value_for_node(pre_read_data, 'gitaly1')
              expect(praefect_manager.value_for_node(post_read_data, 'gitaly2')).to eq praefect_manager.value_for_node(pre_read_data, 'gitaly2')
              expect(praefect_manager.value_for_node(post_read_data, 'gitaly3')).to be > praefect_manager.value_for_node(pre_read_data, 'gitaly3')
            end
          end
        end
      end
    end
  end
end
