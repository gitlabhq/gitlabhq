# frozen_string_literal: true

module QA
  context :geo, :orchestrated, :geo do
    describe 'Geo Nodes API' do
      before(:all) do
        get_personal_access_token
      end

      shared_examples 'retrieving configuration about Geo nodes' do
        it 'GET /geo_nodes' do
          get api_endpoint('/geo_nodes')

          expect_status(200)
          expect(json_body.size).to be >= 2
          expect_json('?', primary: true)
          expect_json_types('*', primary: :boolean, current: :boolean,
                                 files_max_capacity: :integer, repos_max_capacity: :integer,
                                 clone_protocol: :string, _links: :object)
        end

        it 'GET /geo_nodes/:id' do
          get api_endpoint("/geo_nodes/#{geo_node[:id]}")

          expect_status(200)
          expect(json_body).to eq geo_node
        end
      end

      describe 'Geo Nodes API on primary node', :geo do
        before(:context) do
          fetch_nodes(:geo_primary)
        end

        include_examples 'retrieving configuration about Geo nodes' do
          let(:geo_node) { @primary_node }
        end

        describe 'editing a Geo node' do
          it 'PUT /geo_nodes/:id for secondary node' do
            endpoint = api_endpoint("/geo_nodes/#{@secondary_node[:id]}")
            new_attributes = { enabled: false, files_max_capacity: 1000, repos_max_capacity: 2000 }

            put endpoint, new_attributes

            expect_status(200)
            expect_json(new_attributes)

            # restore the original values
            put endpoint, { enabled: @secondary_node[:enabled],
                            files_max_capacity: @secondary_node[:files_max_capacity],
                            repos_max_capacity: @secondary_node[:repos_max_capacity] }

            expect_status(200)
          end
        end
      end

      describe 'Geo Nodes API on secondary node', :geo do
        before(:context) do
          fetch_nodes(:geo_secondary)
        end

        include_examples 'retrieving configuration about Geo nodes' do
          let(:geo_node) { @nodes.first }
        end
      end

      def api_endpoint(endpoint)
        QA::Runtime::API::Request.new(@api_client, endpoint).url
      end

      def fetch_nodes(node_type)
        @api_client = Runtime::API::Client.new(node_type, personal_access_token: @personal_access_token)

        get api_endpoint('/geo_nodes')

        @nodes          = json_body
        @primary_node   = @nodes.detect { |node| node[:primary] == true }
        @secondary_node = @nodes.detect { |node| node[:primary] == false }
      end

      # go to the primary and create a personal_access_token, which will be used
      # for accessing both the primary and secondary
      def get_personal_access_token
        api_client = Runtime::API::Client.new(:geo_primary)
        @personal_access_token = api_client.personal_access_token
      end
    end
  end
end
