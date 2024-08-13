# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::RoleParser, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let(:finder_class) do
    Class.new do
      include Members::RoleParser

      def initialize(params)
        @params = params
      end

      def static
        get_access_level(params[:max_role])
      end

      def custom
        get_member_role_id(params[:max_role])
      end

      private

      attr_reader :params
    end
  end

  subject(:finder) { finder_class.new(max_role: max_role) }

  describe '#static' do
    subject(:static) { finder.static }

    where(:max_role) { [nil, '', 'static', "xstatic-1", "static-1x"] }

    with_them do
      it { is_expected.to be_nil }
    end

    context 'when containing a valid value' do
      let(:max_role) { 'static-1' }

      it { is_expected.to eq(1) }
    end
  end

  describe '#custom' do
    let(:params) { { max_role: max_role } }

    subject(:custom) { finder.custom }

    where(:max_role) { [nil, '', 'custom', "xcustom-1", "custom-1x"] }

    with_them do
      it { is_expected.to be_nil }
    end

    context 'when containing a valid value' do
      let(:max_role) { 'custom-1' }

      it { is_expected.to eq(1) }
    end
  end
end
