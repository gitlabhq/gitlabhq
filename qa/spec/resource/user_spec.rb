# frozen_string_literal: true

RSpec.describe QA::Resource::User do
  let(:api_resource) do
    {
      name: "GitLab QA",
      username: "gitlab-qa",
      web_url: "https://staging.gitlab.com/gitlab-qa",
      public_email: "1614863-gitlab-qa@users.noreply.staging.gitlab.com"
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

  describe '#public_email' do
    it 'defaults to QA::Runtime::User.default_email' do
      expect(subject.public_email).to eq(QA::Runtime::User.default_email)
    end

    it 'retrieves the public_email from the api_resource if present' do
      subject.__send__(:api_resource=, api_resource)

      expect(subject.public_email).to eq(api_resource[:public_email])
    end

    it 'defaults to QA::Runtime::User.default_email if the public_email from the api_resource is blank' do
      subject.__send__(:api_resource=, api_resource.merge(public_email: ''))

      expect(subject.public_email).to eq(QA::Runtime::User.default_email)
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

        expect(index_mock).to receive(:search_user).with(username)
        expect(index_mock).to receive(:has_username?).with(username).and_return(found)

        expect(subject.has_user?(subject)).to eq(found)
      end
    end
  end

  describe '#fabricate_or_use' do
    # Signup Disabled, Personal Access Tokens disabled, method used, method that is not used
    [
      [true,  false, :fabricate_via_api!, :fabricate!],
      [false, false, :fabricate!, :fabricate_via_api!],
      [false, true,  :fabricate!, :fabricate_via_api!],
      [true,  true,  :fabricate!, :fabricate_via_api!]
    ].each do |signup_disabled, personal_access_tokens_disabled, method_used, method_not_used|
      it "when signup_disabled is #{signup_disabled}, "\
         "personal_access_tokens_disabled is #{personal_access_tokens_disabled}, "\
         "calls #{method_used}, does not call #{method_not_used}" do
        allow(QA::Runtime::Env).to receive(:signup_disabled?).and_return(signup_disabled)
        allow(QA::Runtime::Env).to receive(:personal_access_tokens_disabled?)
          .and_return(personal_access_tokens_disabled)

        expect(described_class).to receive(method_used)
        expect(described_class).not_to receive(method_not_used)

        described_class.fabricate_or_use
      end
    end
  end
end
