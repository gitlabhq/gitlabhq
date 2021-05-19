# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe InjectEnterpriseEditionModule do
  let(:extension_name) { 'FF' }
  let(:extension_namespace) { Module.new }
  let(:fish_name) { 'Fish' }
  let(:fish_class) { Class.new }
  let(:fish_extension) { Module.new }

  before do
    # Make sure we're not relying on which mode we're running under
    allow(Gitlab).to receive(:extensions).and_return([extension_name.downcase])

    # Test on an imagined extension and imagined class
    stub_const(fish_name, fish_class) # Fish
    allow(fish_class).to receive(:name).and_return(fish_name)
  end

  shared_examples 'expand the extension with' do |method|
    context 'when extension namespace is set at top-level' do
      before do
        stub_const(extension_name, extension_namespace) # FF
        extension_namespace.const_set(fish_name, fish_extension) # FF::Fish
      end

      it "calls #{method} with the extension module" do
        expect(fish_class).to receive(method).with(fish_extension)

        fish_class.__send__("#{method}_mod_with", fish_name)
      end
    end

    context 'when extension namespace is set at another namespace' do
      let(:another_namespace) { Module.new } # QA

      before do
        another_namespace.const_set(extension_name, extension_namespace) # QA::FF
        extension_namespace.const_set(fish_name, fish_extension) # QA::FF::Fish
      end

      it "calls #{method} with the extension module from the additional namespace" do
        expect(fish_class).to receive(method).with(fish_extension)

        fish_class.__send__("#{method}_mod_with", fish_name, namespace: another_namespace)
      end
    end

    context 'when extension namespace exists but not the extension' do
      before do
        stub_const(extension_name, extension_namespace) # FF
      end

      it "does not call #{method}" do
        expect(fish_class).not_to receive(method).with(fish_extension)

        fish_class.__send__("#{method}_mod_with", fish_name)
      end
    end

    context 'when extension namespace does not exist' do
      it "does not call #{method}" do
        expect(fish_class).not_to receive(method).with(fish_extension)

        fish_class.__send__("#{method}_mod_with", fish_name)
      end
    end
  end

  shared_examples 'expand the assumed extension with' do |method|
    context 'when extension namespace is set at top-level' do
      before do
        stub_const(extension_name, extension_namespace) # FF
        extension_namespace.const_set(fish_name, fish_extension) # FF::Fish
      end

      it "calls #{method} with the extension module" do
        expect(fish_class).to receive(method).with(fish_extension)

        fish_class.__send__("#{method}_mod")
      end
    end

    context 'when extension namespace exists but not the extension' do
      before do
        stub_const(extension_name, extension_namespace) # FF
      end

      it "does not call #{method}" do
        expect(fish_class).not_to receive(method).with(fish_extension)

        fish_class.__send__("#{method}_mod")
      end
    end

    context 'when extension namespace does not exist' do
      it "does not call #{method}" do
        expect(fish_class).not_to receive(method).with(fish_extension)

        fish_class.__send__("#{method}_mod")
      end
    end
  end

  describe '#prepend_mod_with' do
    it_behaves_like 'expand the extension with', :prepend
  end

  describe '#extend_mod_with' do
    it_behaves_like 'expand the extension with', :extend
  end

  describe '#include_mod_with' do
    it_behaves_like 'expand the extension with', :include
  end

  describe '#prepend_mod' do
    it_behaves_like 'expand the assumed extension with', :prepend
  end

  describe '#extend_mod' do
    it_behaves_like 'expand the assumed extension with', :extend
  end

  describe '#include_mod' do
    it_behaves_like 'expand the assumed extension with', :include
  end
end
