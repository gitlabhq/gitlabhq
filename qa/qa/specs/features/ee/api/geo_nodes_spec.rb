module QA
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

    shared_examples 'retrieving status about all Geo nodes' do
      it 'GET /geo_nodes/status' do
        get api_endpoint('/geo_nodes/status')

        expect_status(200)
        expect(json_body.size).to be >= 2

        # only need to check that some of the key values are there
        expect_json_types('*', health: :string,
                               attachments_count: :integer,
                               db_replication_lag_seconds: :integer_or_null,
                               lfs_objects_count: :integer,
                               job_artifacts_count: :integer,
                               projects_count: :integer,
                               repositories_count: :integer,
                               wikis_count: :integer,
                               replication_slots_count: :integer_or_null,
                               version: :string_or_null)
      end
    end

    shared_examples 'retrieving status about a specific Geo node' do
      it 'GET /geo_nodes/:id/status of primary node' do
        get api_endpoint("/geo_nodes/#{@primary_node[:id]}/status")

        expect_status(200)
        expect_json(geo_node_id: @primary_node[:id])
      end

      it 'GET /geo_nodes/:id/status of secondary node' do
        get api_endpoint("/geo_nodes/#{@secondary_node[:id]}/status")

        expect_status(200)
        expect_json(geo_node_id: @secondary_node[:id])
      end

      it 'GET /geo_nodes/:id/status of an invalid node' do
        get api_endpoint("/geo_nodes/1000/status")

        expect_status(404)
      end
    end

    shared_examples 'retrieving project sync failures ocurred on the current node' do
      it 'GET /geo_nodes/current/failures' do
        get api_endpoint("/geo_nodes/current/failures")

        expect_status(200)
        expect(json_body).to be_an Array
      end
    end

    describe 'Geo Nodes API on primary node', :geo do
      before(:context) do
        fetch_nodes(:geo_primary)
      end

      include_examples 'retrieving configuration about Geo nodes' do
        let(:geo_node) { @primary_node }
      end

      include_examples 'retrieving status about all Geo nodes'
      include_examples 'retrieving status about a specific Geo node'

      describe 'editing a Geo node' do
        it 'PUT /geo_nodes/:id for primary node' do
          put api_endpoint("/geo_nodes/#{@primary_node[:id]}"),
              { params: { files_max_capacity: 1000 } }

          expect_status(403)
        end

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

        it 'PUT /geo_nodes/:id for an invalid node' do
          put api_endpoint("/geo_nodes/1000"),
              { params: { files_max_capacity: 1000 } }

          expect_status(404)
        end
      end

      describe 'repairing a Geo node' do
        it 'POST /geo_nodes/:id/repair for primary node' do
          post api_endpoint("/geo_nodes/#{@primary_node[:id]}/repair")

          expect_status(200)
          expect_json(geo_node_id: @primary_node[:id])
        end

        it 'POST /geo_nodes/:id/repair for secondary node' do
          post api_endpoint("/geo_nodes/#{@secondary_node[:id]}/repair")

          expect_status(200)
          expect_json(geo_node_id: @secondary_node[:id])
        end

        it 'POST /geo_nodes/:id/repair for an invalid node' do
          post api_endpoint("/geo_nodes/1000/repair")

          expect_status(404)
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

      include_examples 'retrieving status about all Geo nodes'
      include_examples 'retrieving status about a specific Geo node'
      include_examples 'retrieving project sync failures ocurred on the current node'

      it 'GET /geo_nodes is not current' do
        get api_endpoint('/geo_nodes')

        expect_status(200)
        expect_json('?', current: false)
      end

      describe 'editing a Geo node' do
        it 'PUT /geo_nodes/:id for primary node' do
          put api_endpoint("/geo_nodes/#{@primary_node[:id]}"),
              { params: { files_max_capacity: 1000 } }

          expect_status(403)
        end

        it 'PUT /geo_nodes/:id for secondary node' do
          put api_endpoint("/geo_nodes/#{@secondary_node[:id]}"),
              { params: { files_max_capacity: 1000 } }

          expect_status(403)
        end

        it 'PUT /geo_nodes/:id for an invalid node' do
          put api_endpoint('/geo_nodes/1000'),
              { params: { files_max_capacity: 1000 } }

          expect_status(403)
        end
      end

      describe 'repairing a Geo node' do
        it 'POST /geo_nodes/:id/repair for primary node' do
          post api_endpoint("/geo_nodes/#{@primary_node[:id]}/repair")

          expect_status(403)
        end

        it 'POST /geo_nodes/:id/repair for secondary node' do
          post api_endpoint("/geo_nodes/#{@secondary_node[:id]}/repair")

          expect_status(403)
        end

        it 'POST /geo_nodes/:id/repair for an invalid node' do
          post api_endpoint('/geo_nodes/1000/repair')

          expect_status(403)
        end
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
