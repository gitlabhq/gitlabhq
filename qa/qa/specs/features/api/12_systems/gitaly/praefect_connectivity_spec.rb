# frozen_string_literal: true

module QA
  RSpec.describe 'Systems' do
    describe 'Praefect connectivity commands', :orchestrated, :gitaly_cluster, product_group: :gitaly do
      praefect_manager = Service::PraefectManager.new

      before do
        praefect_manager.start_all_nodes
      end

      context 'in a healthy environment' do
        it 'confirms healthy connection to database',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349937' do
          expect(praefect_manager.praefect_sql_ping_healthy?).to be true
        end

        it 'confirms healthy connection to gitaly nodes',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349938' do
          expect(praefect_manager.wait_for_dial_nodes_successful).to be true
        end
      end

      context 'in an unhealthy environment' do
        it 'diagnoses unhealthy connection to database',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349939' do
          praefect_manager.stop_node(praefect_manager.postgres)
          expect(praefect_manager.praefect_sql_ping_healthy?).to be false
        end

        it 'diagnoses connection issues to gitaly nodes',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349940' do
          praefect_manager.stop_node(praefect_manager.primary_node)
          praefect_manager.stop_node(praefect_manager.tertiary_node)
          expect(praefect_manager.praefect_dial_nodes_status?(praefect_manager.primary_node, false)).to be true
          expect(praefect_manager.praefect_dial_nodes_status?(praefect_manager.secondary_node)).to be true
          expect(praefect_manager.praefect_dial_nodes_status?(praefect_manager.tertiary_node, false)).to be true

          praefect_manager.stop_node(praefect_manager.secondary_node)
          expect(praefect_manager.praefect_dial_nodes_status?(praefect_manager.secondary_node, false)).to be true
        end
      end
    end
  end
end
