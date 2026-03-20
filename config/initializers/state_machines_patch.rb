# frozen_string_literal: true

if Gem::Version.new(StateMachines::VERSION) > Gem::Version.new('0.100.4')
  raise 'New version of state_machines detected, please remove or update this patch'
end

module StateMachinesMachineConfigurationPatch
  # From https://github.com/state-machines/state_machines/blob/06da14151e91e4662dc714e85655ca7912e18baf/lib/state_machines/machine/configuration.rb#L109
  # It is the same method, minus the code used to output a warning
  # rubocop:disable Gitlab/ModuleWithInstanceVariables -- upstream code
  def initial_state=(new_initial_state)
    @initial_state = new_initial_state
    add_states([@initial_state]) unless dynamic_initial_state?
    states.each { |state| state.initial = (state.name == @initial_state) }
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def warn_conflicting_initial_state
    initial_state = states.detect(&:initial)
    has_owner_default = !owner_class_attribute_default.nil?
    has_conflicting_default = dynamic_initial_state? || !owner_class_attribute_default_matches?(initial_state)
    return unless has_owner_default && has_conflicting_default

    warn(
      "Both #{owner_class.name} and its #{name.inspect} machine have defined " \
        "a different default for \"#{attribute}\". Use only one or the other for " \
        'defining defaults to avoid unexpected behaviors.'
    )
  end
end

StateMachines::Machine::Configuration.prepend(StateMachinesMachineConfigurationPatch)
