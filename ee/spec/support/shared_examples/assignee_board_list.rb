# frozen_string_literal: true
shared_examples_for 'assignee board list' do
  context 'when assignee_id is sent' do
    it 'returns 400 if user is not found' do
      other_user = create(:user)
      post api(url, user), assignee_id: other_user.id

      expect(response).to have_gitlab_http_status(400)
      expect(json_response.dig('message', 'error')).to eq('User not found!')
    end

    it 'returns 400 if assignee list feature is not available' do
      stub_licensed_features(board_assignee_lists: false)

      post api(url, user), assignee_id: user.id

      expect(response).to have_gitlab_http_status(400)
      expect(json_response.dig('message', 'list_type'))
          .to contain_exactly('Assignee lists not available with your current license')
    end

    it 'creates an assignee list if user is found' do
      stub_licensed_features(board_assignee_lists: true)

      post api(url, user), assignee_id: user.id

      expect(response).to have_gitlab_http_status(201)
      expect(json_response.dig('assignee', 'id')).to eq(user.id)
    end
  end
end
