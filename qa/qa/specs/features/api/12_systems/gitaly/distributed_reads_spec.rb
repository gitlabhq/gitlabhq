# frozen_string_literal: true

require 'parallel'

module QA
  RSpec.describe 'Systems', product_group: :gitaly do
    describe 'Gitaly distributed reads', :orchestrated, :gitaly_cluster, :skip_live_env, :requires_admin do
      let(:number_of_reads_per_loop) { 9 }
      let(:praefect_manager) { Service::PraefectManager.new }
      let(:project) do
        Resource::Project.fabricate! do |project|
          project.name = "gitaly_cluster"
          project.initialize_with_readme = true
        end
      end

      before do
        praefect_manager.start_all_nodes
        praefect_manager.wait_for_replication(project.id)
      end

      it 'reads from each node',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347833' do
        pre_read_data = praefect_manager.query_read_distribution

        wait_for_reads_to_increase(project, number_of_reads_per_loop, pre_read_data)

        aggregate_failures "each gitaly node" do
          praefect_manager.query_read_distribution.each_with_index do |data, index|
            pre_read_count = praefect_manager.value_for_node(pre_read_data, data[:node])
            QA::Runtime::Logger.debug("Node: #{data[:node]}; before: #{pre_read_count}; now: #{data[:value]}")
            expect(data[:value]).to be > pre_read_count, "Read counts did not differ for node #{data[:node]}"
          end
        end
      end

      context 'when a node is unhealthy' do
        before do
          praefect_manager.stop_node(praefect_manager.secondary_node)
        end

        after do
          # Leave the cluster in a suitable state for subsequent tests
          praefect_manager.start_node(praefect_manager.secondary_node)
        end

        it 'does not read from the unhealthy node',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347834' do
          pre_read_data = praefect_manager.query_read_distribution

          read_from_project(project, number_of_reads_per_loop * 10)

          praefect_manager.wait_for_read_count_change(pre_read_data)

          post_read_data = praefect_manager.query_read_distribution

          aggregate_failures "each gitaly node" do
            expect(praefect_manager.value_for_node(post_read_data, 'gitaly1'))
              .to be > praefect_manager.value_for_node(pre_read_data, 'gitaly1')
            expect(praefect_manager.value_for_node(post_read_data, 'gitaly2'))
              .to eq praefect_manager.value_for_node(pre_read_data, 'gitaly2')
            expect(praefect_manager.value_for_node(post_read_data, 'gitaly3'))
              .to be > praefect_manager.value_for_node(pre_read_data, 'gitaly3')
          end
        end
      end

      def read_from_project(project, number_of_reads)
        QA::Runtime::Logger.info('Reading from the repository')
        Parallel.each((1..number_of_reads)) do
          Git::Repository.perform do |repository|
            repository.uri = project.repository_http_location.uri
            repository.use_default_credentials
            repository.clone
          end
        end
      end

      def wait_for_reads_to_increase(project, number_of_reads, pre_read_data)
        diff_found = pre_read_data

        Support::Waiter.wait_until(sleep_interval: 5, raise_on_failure: false) do
          read_from_project(project, number_of_reads)

          praefect_manager.query_read_distribution.each_with_index do |data, index|
            diff_found[index] = {} unless diff_found[index]
            if data[:value] > praefect_manager.value_for_node(pre_read_data, data[:node])
              diff_found[index][:diff] = true
            end
          end
          diff_found.all? { |node| node.key?(:diff) && node[:diff] }
        end
      end
    end
  end
end
