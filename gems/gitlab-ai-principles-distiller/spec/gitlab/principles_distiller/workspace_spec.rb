# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'gitlab/principles_distiller/workspace'

RSpec.describe Gitlab::PrinciplesDistiller::Workspace do
  let(:tmpdir) { Dir.mktmpdir }
  let!(:original_path) { described_class.instance_variable_get(:@path) }

  before do
    described_class.path = tmpdir
  end

  after do
    described_class.instance_variable_set(:@path, original_path)
    FileUtils.remove_entry(tmpdir)
  end

  describe '.safe_join' do
    subject(:safe_join) { described_class.safe_join(*segments) }

    context 'with a simple relative path' do
      let(:segments) { ['doc/development/sql.md'] }

      it { is_expected.to eq(File.join(tmpdir, 'doc/development/sql.md')) }
    end

    context 'with multiple segments' do
      let(:segments) { %w[doc development sql.md] }

      it { is_expected.to eq(File.join(tmpdir, 'doc', 'development', 'sql.md')) }
    end

    context 'with no segments' do
      let(:segments) { [] }

      it { is_expected.to eq(tmpdir) }
    end

    context 'with a traversal segment that starts with `..`' do
      let(:segments) { ['../etc/passwd'] }

      it 'raises PathTraversalError' do
        expect { safe_join }.to raise_error(described_class::PathTraversalError, /Path traversal detected/)
      end
    end

    context 'with a traversal segment that contains `..` mid-path' do
      let(:segments) { ['doc/../../etc/passwd'] }

      it 'raises PathTraversalError' do
        expect { safe_join }.to raise_error(described_class::PathTraversalError, /Path traversal detected/)
      end
    end

    context 'with a traversal segment that ends with `..`' do
      let(:segments) { ['doc/..'] }

      it 'raises PathTraversalError' do
        expect { safe_join }.to raise_error(described_class::PathTraversalError, /Path traversal detected/)
      end
    end

    context 'with a traversal segment that is just `..`' do
      let(:segments) { ['..'] }

      it 'raises PathTraversalError' do
        expect { safe_join }.to raise_error(described_class::PathTraversalError, /Path traversal detected/)
      end
    end

    context 'with a safe segment followed by a traversal segment' do
      let(:segments) { ['doc', '../etc', 'passwd'] }

      it 'raises PathTraversalError' do
        expect { safe_join }.to raise_error(described_class::PathTraversalError, /Path traversal detected/)
      end
    end

    context 'with backslash-style traversal sequences' do
      let(:segments) { ['..\\etc\\passwd'] }

      it 'raises PathTraversalError' do
        expect { safe_join }.to raise_error(described_class::PathTraversalError, /Path traversal detected/)
      end
    end
  end

  describe '.check_path_traversal!' do
    subject(:check_path_traversal!) { described_class.check_path_traversal!(segment) }

    context 'with a safe segment' do
      let(:segment) { 'doc/development/sql.md' }

      it { is_expected.to be_nil }
    end

    context 'with a nil segment' do
      let(:segment) { nil }

      it { is_expected.to be_nil }
    end

    context 'with a non-string segment' do
      let(:segment) { 123 }

      it 'raises PathTraversalError' do
        expect { check_path_traversal! }.to raise_error(described_class::PathTraversalError, /Invalid path/)
      end
    end

    context 'with a `..` segment' do
      let(:segment) { '../etc' }

      it 'raises PathTraversalError' do
        expect { check_path_traversal! }.to raise_error(described_class::PathTraversalError, /Path traversal detected/)
      end
    end
  end
end
