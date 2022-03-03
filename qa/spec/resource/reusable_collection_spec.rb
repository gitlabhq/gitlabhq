# frozen_string_literal: true

RSpec.describe QA::Resource::ReusableCollection do
  let(:reusable_resource_class) do
    Class.new do
      prepend QA::Resource::Reusable

      attr_reader :removed

      def self.name
        'FooReusableResource'
      end

      def comparable
        self.class.name
      end

      def remove_via_api!
        @removed = true
      end

      def exists?() end

      def reload!
        Struct.new(:api_resource).new({ marked_for_deletion_on: false })
      end
    end
  end

  let(:another_reusable_resource_class) do
    Class.new(reusable_resource_class) do
      def self.name
        'BarReusableResource'
      end
    end
  end

  let(:a_resource_instance) { reusable_resource_class.new }
  let(:another_resource_instance) { another_reusable_resource_class.new }

  it 'is a singleton class' do
    expect { described_class.new }.to raise_error(NoMethodError)
  end

  subject(:collection) do
    described_class.instance
  end

  before do
    described_class.register_resource_classes do |c|
      reusable_resource_class.register(c)
      another_reusable_resource_class.register(c)
    end

    collection.resource_classes = {
      'FooReusableResource' => {
        reuse_as_identifier: {
          resource: a_resource_instance
        }
      },
      'BarReusableResource' => {
        another_reuse_as_identifier: {
          resource: another_resource_instance
        }
      }
    }

    allow(a_resource_instance).to receive(:validate_reuse)
    allow(another_resource_instance).to receive(:validate_reuse)
  end

  after do
    collection.resource_classes = {}
  end

  describe '#each_resource' do
    it 'yields each resource and reuse_as identifier in the collection' do
      expect { |blk| collection.each_resource(&blk) }
        .to yield_successive_args(
          [:reuse_as_identifier, a_resource_instance],
          [:another_reuse_as_identifier, another_resource_instance]
        )
    end
  end

  describe '.remove_all_via_api!' do
    before do
      allow(a_resource_instance).to receive(:exists?).and_return(true)
      allow(another_resource_instance).to receive(:exists?).and_return(true)
    end

    it 'removes each instance of each resource class' do
      described_class.remove_all_via_api!

      expect(a_resource_instance.removed).to be_truthy
      expect(another_resource_instance.removed).to be_truthy
    end

    context 'when a resource is marked for deletion' do
      before do
        marked_for_deletion = Struct.new(:api_resource).new({ marked_for_deletion_on: true })

        allow(a_resource_instance).to receive(:reload!).and_return(marked_for_deletion)
        allow(another_resource_instance).to receive(:reload!).and_return(marked_for_deletion)
      end

      it 'does not remove the resource' do
        expect(a_resource_instance.removed).to be_falsey
        expect(another_resource_instance.removed).to be_falsy
      end
    end
  end

  describe '.validate_resource_reuse' do
    it 'validates each instance of each resource class' do
      expect(a_resource_instance).to receive(:validate_reuse)
      expect(another_resource_instance).to receive(:validate_reuse)

      described_class.validate_resource_reuse
    end
  end

  describe '.register_resource_classes' do
    it 'yields the hash of resource classes in the collection' do
      expect { |blk| described_class.register_resource_classes(&blk) }.to yield_with_args(collection.resource_classes)
    end
  end
end
