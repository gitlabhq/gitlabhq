require "spec_helper"

describe "mail_room.yml" do
  let(:config_path)   { "config/mail_room.yml" }
  let(:configuration) { YAML.load(ERB.new(File.read(config_path)).result) }

  context "when incoming email is disabled" do
    before do
      ENV["MAIL_ROOM_GITLAB_CONFIG_FILE"] = Rails.root.join("spec/fixtures/mail_room_disabled.yml").to_s
    end

    after do
      ENV["MAIL_ROOM_GITLAB_CONFIG_FILE"] = nil
    end

    it "contains no configuration" do
      expect(configuration[:mailboxes]).to be_nil
    end
  end

  context "when incoming email is enabled" do
    before do
      ENV["MAIL_ROOM_GITLAB_CONFIG_FILE"] = Rails.root.join("spec/fixtures/mail_room_enabled.yml").to_s
    end

    after do
      ENV["MAIL_ROOM_GITLAB_CONFIG_FILE"] = nil
    end

    it "contains the intended configuration" do
      expect(configuration[:mailboxes].length).to eq(1)

      mailbox = configuration[:mailboxes].first

      expect(mailbox[:host]).to eq("imap.gmail.com")
      expect(mailbox[:port]).to eq(993)
      expect(mailbox[:ssl]).to eq(true)
      expect(mailbox[:start_tls]).to eq(false)
      expect(mailbox[:email]).to eq("gitlab-incoming@gmail.com")
      expect(mailbox[:password]).to eq("[REDACTED]")
      expect(mailbox[:name]).to eq("inbox")

      redis_config_file = Rails.root.join('config', 'resque.yml')

      redis_url =
        if File.exists?(redis_config_file)
          YAML.load_file(redis_config_file)[Rails.env]
        else
          "redis://localhost:6379"
        end

      expect(mailbox[:delivery_options][:redis_url]).to eq(redis_url)
      expect(mailbox[:arbitration_options][:redis_url]).to eq(redis_url)
    end
  end
end
