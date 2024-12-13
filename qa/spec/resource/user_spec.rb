# frozen_string_literal: true

RSpec.describe QA::Resource::User do
  let(:api_resource) do
    {
      name: "GitLab QA",
      username: "gitlab-qa",
      web_url: "https://staging.gitlab.com/gitlab-qa",
      commit_email: "1614863-gitlab-qa@users.noreply.staging.gitlab.com"
    }
  end

  describe '#username' do
    it 'generates a default username' do
      expect(subject.username).to match(/qa-user-\w+/)
    end

    it 'is possible to set the username' do
      subject.username = 'johndoe'

      expect(subject.username).to eq('johndoe')
    end
  end

  describe '#password' do
    it 'generates a default password' do
      expect(subject.password).to match('Pa$$w0rd')
    end

    it 'is possible to set the password' do
      new_password = "21c7a808"
      subject.password = new_password

      expect(subject.password).to eq(new_password)
    end
  end

  describe '#name' do
    it 'defaults to a name based on the username' do
      expect(subject.name).to match(/#{subject.username.tr('-', ' ')}/i)
    end

    it 'retrieves the name from the api_resource if present' do
      subject.__send__(:api_resource=, api_resource)

      expect(subject.name).to eq(api_resource[:name])
    end

    it 'is possible to set the name' do
      subject.name = 'John Doe'

      expect(subject.name).to eq('John Doe')
    end
  end

  describe '#email' do
    it 'defaults to the <username>@example.com' do
      expect(subject.email).to eq("#{subject.username}@example.com")
    end

    it 'is possible to set the email' do
      subject.email = 'johndoe@example.org'

      expect(subject.email).to eq('johndoe@example.org')
    end
  end

  describe '#commit_email' do
    it 'retrieves the commit_email from the api_resource if present' do
      subject.__send__(:api_resource=, api_resource)

      expect(subject.commit_email).to eq(api_resource[:commit_email])
    end
  end

  describe '#credentials_given?' do
    it 'returns false when username and email have not been overridden' do
      expect(subject).not_to be_credentials_given
    end

    it 'returns false even after username and email have been called' do
      # Call #username and #password to ensure this doesn't set their respective
      # instance variable.
      subject.username
      subject.password

      expect(subject).not_to be_credentials_given
    end

    it 'returns false if only the username has been overridden' do
      subject.username = 'johndoe'

      expect(subject).not_to be_credentials_given
    end

    it 'returns false if only the password has been overridden' do
      subject.password = 'secret'

      expect(subject).not_to be_credentials_given
    end

    it 'returns true if both the username and password have been overridden' do
      subject.username = 'johndoe'
      subject.password = 'secret'

      expect(subject).to be_credentials_given
    end
  end

  describe '#has_user?' do
    let(:index_mock) do
      instance_double(QA::Page::Admin::Overview::Users::Index)
    end

    users = [
      ['foo', true],
      ['bar', false]
    ]

    users.each do |(username, found)|
      it "returns #{found} when has_username returns #{found}" do
        subject.username = username

        allow(QA::Flow::Login).to receive(:while_signed_in_as_admin).and_yield
        allow(QA::Page::Main::Menu).to receive(:perform)
        allow(QA::Page::Admin::Menu).to receive(:perform)
        allow(QA::Page::Admin::Overview::Users::Index).to receive(:perform).and_yield(index_mock)

        expect(index_mock).to receive(:choose_search_user).with(username)
        expect(index_mock).to receive(:click_search)
        expect(index_mock).to receive(:has_username?).with(username).and_return(found)

        expect(subject.has_user?(subject)).to eq(found)
      end
    end
  end
end
