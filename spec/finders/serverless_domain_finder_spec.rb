# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServerlessDomainFinder do
  let(:function_name) { 'test-function' }
  let(:pages_domain_name) { 'serverless.gitlab.io' }
  let(:valid_cluster_uuid) { 'aba1cdef123456f278' }
  let(:invalid_cluster_uuid) { 'aba1cdef123456f178' }
  let!(:environment) { create(:environment, name: 'test') }

  let(:pages_domain) do
    create(
      :pages_domain,
      :instance_serverless,
      domain: pages_domain_name
    )
  end

  let(:knative_with_ingress) do
    create(
      :clusters_applications_knative,
      external_ip: '10.0.0.1'
    )
  end

  let!(:serverless_domain_cluster) do
    create(
      :serverless_domain_cluster,
      uuid: 'abcdef12345678',
      pages_domain: pages_domain,
      knative: knative_with_ingress
    )
  end

  let(:valid_uri) { "https://#{function_name}-#{valid_cluster_uuid}#{"%x" % environment.id}-#{environment.slug}.#{pages_domain_name}" }
  let(:valid_fqdn) { "#{function_name}-#{valid_cluster_uuid}#{"%x" % environment.id}-#{environment.slug}.#{pages_domain_name}" }
  let(:invalid_uri) { "https://#{function_name}-#{invalid_cluster_uuid}#{"%x" % environment.id}-#{environment.slug}.#{pages_domain_name}" }

  let(:valid_finder) { described_class.new(valid_uri) }
  let(:invalid_finder) { described_class.new(invalid_uri) }

  describe '#serverless?' do
    context 'with a valid URI' do
      subject { valid_finder.serverless? }

      it { is_expected.to be_truthy }
    end

    context 'with an invalid URI' do
      subject { invalid_finder.serverless? }

      it { is_expected.to be_falsy }
    end
  end

  describe '#serverless_domain_cluster_uuid' do
    context 'with a valid URI' do
      subject { valid_finder.serverless_domain_cluster_uuid }

      it { is_expected.to eq serverless_domain_cluster.uuid }
    end

    context 'with an invalid URI' do
      subject { invalid_finder.serverless_domain_cluster_uuid }

      it { is_expected.to be_nil }
    end
  end

  describe '#execute' do
    context 'with a valid URI' do
      let(:serverless_domain) do
        create(
          :serverless_domain,
          function_name: function_name,
          serverless_domain_cluster: serverless_domain_cluster,
          environment: environment
        )
      end

      subject { valid_finder.execute }

      it 'has the correct function_name' do
        expect(subject.function_name).to eq function_name
      end

      it 'has the correct serverless_domain_cluster' do
        expect(subject.serverless_domain_cluster).to eq serverless_domain_cluster
      end

      it 'has the correct environment' do
        expect(subject.environment).to eq environment
      end
    end

    context 'with an invalid URI' do
      subject { invalid_finder.execute }

      it { is_expected.to be_nil }
    end
  end
end
