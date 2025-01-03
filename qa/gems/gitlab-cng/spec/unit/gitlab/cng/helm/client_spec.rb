# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Helm::Client do
  subject(:client) { described_class.new }

  let(:repository_cache) { nil }

  before do
    allow(client).to receive(:execute_shell).and_return("")
  end

  around do |example|
    ClimateControl.modify({ "CNG_HELM_REPOSITORY_CACHE" => repository_cache }) { example.run }
  end

  describe "#add_gitlab_helm_chart" do
    let(:tmpdir) { Dir.mktmpdir("cng") }

    before do
      allow(Gitlab::Cng::Helpers::Utils).to receive(:tmp_dir).and_return(tmpdir)
    end

    context "with default chart" do
      it "adds default chart repo" do
        expect do
          expect(client.add_gitlab_helm_chart).to eq("gitlab/gitlab")
        end.to output(%r{Adding helm chart 'https://charts.gitlab.io'}).to_stdout

        expect(client).to have_received(:execute_shell).with(
          %w[helm repo add gitlab https://charts.gitlab.io],
          stdin_data: nil
        )
      end

      it "updates chart repo when repository already exists" do
        allow(client).to receive(:execute_shell)
          .with(%w[helm repo add gitlab https://charts.gitlab.io], stdin_data: nil)
          .and_raise(Gitlab::Cng::Helpers::Shell::CommandFailure.new(
            "repository name (gitlab) already exists"
          ))

        expect do
          expect(client.add_gitlab_helm_chart).to eq("gitlab/gitlab")
        end.to output(/helm chart repo already exists, updating/).to_stdout
      end

      it "correctly raises error if command fails" do
        allow(client).to receive(:execute_shell)
          .with(%w[helm repo add gitlab https://charts.gitlab.io], stdin_data: nil)
          .and_raise(Gitlab::Cng::Helpers::Shell::CommandFailure.new("something went wrong"))

        expect { expect { client.add_gitlab_helm_chart }.to raise_error("something went wrong") }.to output.to_stdout
      end
    end

    context "with specific chart sha" do
      let(:repository_cache) { tmpdir }
      let(:sha) { "1888fda881ab" }
      let(:chart_dir) { File.join(tmpdir, "gitlab-#{sha}") }
      let(:chart_tgz) { File.join(chart_dir, "gitlab-#{sha}.tgz") }
      let(:cached_chart_tgz) { File.join(repository_cache, "gitlab-#{sha}.tgz") }

      before do
        allow(Net::HTTP).to receive(:get_response).with(
          URI("https://gitlab.com/gitlab-org/charts/gitlab/-/archive/#{sha}/gitlab-#{sha}.tar")
        ).and_return(instance_double(Net::HTTPSuccess, body: "archive", code: "200"))

        FileUtils.mkdir_p(chart_dir)
        FileUtils.touch(chart_tgz)
      end

      it "packages chart from specific sha" do
        expect do
          expect(client.add_gitlab_helm_chart(sha)).to eq(chart_tgz)
        end.to output(/Packaging chart for git sha '#{sha}'/).to_stdout

        expect(client).to have_received(:execute_shell).with(
          %W[tar -xf #{File.join(tmpdir, "gitlab-#{sha}.tar")} -C #{tmpdir}]
        )
        expect(client).to have_received(:execute_shell).with(
          %W[helm package --dependency-update --destination #{chart_dir} #{chart_dir}
            --repository-cache #{repository_cache}],
          stdin_data: nil
        )
        expect(File.exist?(cached_chart_tgz)).to be(true), "Expected packaged chart to be copied to cache dir"
      end

      context "with packaged chart in cache" do
        before do
          FileUtils.touch(cached_chart_tgz)
        end

        it "uses cached chart archive" do
          expect do
            expect(client.add_gitlab_helm_chart(sha)).to eq(cached_chart_tgz)
          end.to output(/Cached version of chart found at #{cached_chart_tgz}, skipping packaging/).to_stdout
        end
      end
    end

    context "with custom repository cache folder" do
      let(:repository_cache) { tmpdir }

      it "uses custom repository cache folder for helm commands" do
        expect { client.add_gitlab_helm_chart }.to output.to_stdout

        expect(client).to have_received(:execute_shell).with(
          %W[helm repo add gitlab https://charts.gitlab.io --repository-cache #{repository_cache}],
          stdin_data: nil
        )
      end
    end
  end

  describe "#upgrade" do
    let(:values) { { vals: "vals" }.to_yaml }

    before do
      allow(client).to receive(:execute_shell).and_return("helm upgrade command output")
    end

    it "runs helm upgrade command" do
      expect do
        client.upgrade(
          "gitlab", "gitlab/gitlab", namespace: "gitlab", timeout: "10m", values: values, args: ["--dry-run"]
        )
      end.to output(
        match(/Upgrading helm release 'gitlab' in namespace 'gitlab'/).and(match(/helm upgrade command output/))
      ).to_stdout

      expect(client).to have_received(:execute_shell).with(%w[
        helm upgrade --install gitlab gitlab/gitlab
        --namespace gitlab
        --timeout 10m
        --values -
        --wait
        --dry-run
      ], stdin_data: values)
    end
  end

  describe "#status" do
    it "returns status details when release present" do
      allow(client).to receive(:execute_shell)
        .with(%w[helm status gitlab --namespace gitlab], stdin_data: nil)
        .and_return("status")

      expect(client.status("gitlab", namespace: "gitlab")).to eq("status")
    end

    it "return nil when release not present" do
      allow(client).to receive(:execute_shell)
       .with(%w[helm status gitlab --namespace gitlab], stdin_data: nil)
       .and_raise(Gitlab::Cng::Helpers::Shell::CommandFailure.new("release: not found"))

      expect(client.status("gitlab", namespace: "gitlab")).to be_nil
    end

    it "raises error when command fails" do
      allow(client).to receive(:execute_shell)
        .with(%w[helm status gitlab --namespace gitlab], stdin_data: nil)
        .and_raise(Gitlab::Cng::Helpers::Shell::CommandFailure.new("something went wrong"))

      expect { client.status("gitlab", namespace: "gitlab") }.to raise_error("something went wrong")
    end
  end

  describe "#uninstall" do
    it "runs helm uninstall command" do
      expect do
        client.uninstall("gitlab", namespace: "gitlab", timeout: "10m")
      end.to output(/Uninstalling helm release 'gitlab' in namespace 'gitlab'/).to_stdout

      expect(client).to have_received(:execute_shell).with(
        %w[helm uninstall gitlab --namespace gitlab --timeout 10m --wait],
        stdin_data: nil
      )
    end
  end
end
