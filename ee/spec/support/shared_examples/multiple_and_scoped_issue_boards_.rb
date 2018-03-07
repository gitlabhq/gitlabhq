shared_examples_for 'multiple and scoped issue boards' do |route_definition|
  let(:root_url) { route_definition.gsub(":id", board_parent.id.to_s) }

  context 'multiple issue boards' do
    before do
      board_parent.add_reporter(user)
      stub_licensed_features(multiple_group_issue_boards: true, multiple_project_issue_boards: true)
    end

    describe "POST #{route_definition}" do
      it 'creates a board' do
        post api(root_url, user), name: "new board"

        expect(response).to have_gitlab_http_status(201)

        expect(response).to match_response_schema('public_api/v4/board', dir: "ee")
      end
    end

    describe "DELETE #{route_definition}" do
      let(:url) { "#{root_url}/#{board.id}" }

      it 'deletes a board' do
        delete api(url, user)

        expect(response).to have_gitlab_http_status(204)
      end
    end
  end

  context 'with the scoped_issue_board-feature available' do
    it 'returns the milestone when the `scoped_issue_board` feature is enabled' do
      stub_licensed_features(scoped_issue_board: true)

      get api(root_url, user)

      expect(json_response.first["milestone"]).not_to be_nil
    end

    it 'hides the milestone when the `scoped_issue_board` feature is disabled' do
      stub_licensed_features(scoped_issue_board: false)

      get api(root_url, user)

      expect(json_response.first["milestone"]).to be_nil
    end
  end
end
