# frozen_string_literal: true

describe QA::Resource::User do
  describe "#fabricate_via_api!" do
    response = Struct.new(:code, :body)

    it 'fetches an existing user' do
      existing_users = [
        {
          id: '0',
          name: 'name',
          username: 'name',
          web_url: ''
        }
      ]
      users_response = response.new('200', JSON.dump(existing_users))
      single_user_response = response.new('200', JSON.dump(existing_users.first))

      expect(subject).to receive(:api_get_from).with("/users?username=name").and_return(users_response)
      expect(subject).to receive(:api_get_from).with("/users/0").and_return(single_user_response)

      subject.username = 'name'
      subject.fabricate_via_api!

      expect(subject.api_response).to eq(existing_users.first)
    end

    it 'tries to create a user if it does not exist' do
      expect(subject).to receive(:api_get_from).with("/users?username=foo").and_return(response.new('200', '[]'))
      expect(subject).to receive(:api_post).and_return({ web_url: '' })

      subject.username = 'foo'
      subject.fabricate_via_api!
    end
  end
end
