# frozen_string_literal: true

module NextFoundInstanceOf
  ERROR_MESSAGE = 'NextFoundInstanceOf mock helpers can only be used with ActiveRecord targets'
  HELPER_METHOD_PATTERN = /(?:allow|expect)_next_found_(?<number>\d+)_instances_of/

  def method_missing(method_name, ...)
    match_data = method_name.match(HELPER_METHOD_PATTERN)
    return super unless match_data

    helper_method = method_name.to_s.sub("_#{match_data[:number]}", '')

    public_send(helper_method, *args, match_data[:number].to_i, &block) # rubocop:disable GitlabSecurity/PublicSend -- it is safe
  end

  def respond_to_missing?(method_name, ...)
    match_data = method_name.match(HELPER_METHOD_PATTERN)
    return super unless match_data

    helper_method = method_name.to_s.sub("_#{match_data[:number]}", '')
    helper_method.respond_to_missing?(helper_method, *args, &block)
  end

  def expect_next_found_instance_of(klass, &block)
    expect_next_found_instances_of(klass, nil, &block)
  end

  def expect_next_found_instances_of(klass, number, &block)
    check_if_active_record!(klass)

    stub_allocate(expect(klass), klass, number, &block)
  end

  def allow_next_found_instance_of(klass, &block)
    allow_next_found_instances_of(klass, nil, &block)
  end

  def allow_next_found_instances_of(klass, number, &block)
    check_if_active_record!(klass)

    stub_allocate(allow(klass), klass, number, &block)
  end

  private

  def check_if_active_record!(klass)
    raise ArgumentError, ERROR_MESSAGE unless klass < ActiveRecord::Base
  end

  def stub_allocate(target, klass, number, &_block)
    stub = receive(:allocate)
    stub.exactly(number).times if number

    target.to stub.and_wrap_original do |method|
      method.call.tap do |allocation|
        # ActiveRecord::Core.allocate returns a frozen object:
        # https://github.com/rails/rails/blob/291a3d2ef29a3842d1156ada7526f4ee60dd2b59/activerecord/lib/active_record/core.rb#L620
        # It's unexpected behavior and probably a bug in Rails
        # Let's work it around by setting the attributes to default to unfreeze the object for now
        allocation.instance_variable_set(:@attributes, klass._default_attributes)

        yield(allocation)
      end
    end
  end
end
