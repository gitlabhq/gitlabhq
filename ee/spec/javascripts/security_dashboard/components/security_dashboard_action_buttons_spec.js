import Vue from 'vue';
import Vuex from 'vuex';
import component from 'ee/security_dashboard/components/security_dashboard_action_buttons.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

describe('Security Dashboard Action Buttons', () => {
  let vm;
  let props;
  let actions;

  beforeEach(() => {
    props = { vulnerability: { id: 123 } };
    actions = {
      newIssue: jasmine.createSpy('newIssue'),
      dismissVulnerability: jasmine.createSpy('dismissVulnerability'),
    };
    const Component = Vue.extend(component);
    const store = new Vuex.Store({ actions });

    vm = mountComponentWithStore(Component, { props, store });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render three buttons', () => {
    expect(vm.$el.querySelectorAll('.btn')).toHaveLength(3);
  });

  describe('More Info Button', () => {
    it('should render the More info button', () => {
      expect(vm.$el.querySelector('.js-more-info')).not.toBeNull();
    });
  });

  describe('New Issue Button', () => {
    it('should render the New Issue button', () => {
      expect(vm.$el.querySelector('.js-new-issue')).not.toBeNull();
    });

    it('should trigger the `newIssue` action when clicked', () => {
      vm.$el.querySelector('.js-new-issue').click();

      expect(actions.newIssue).toHaveBeenCalledTimes(1);
    });
  });

  describe('Dismiss Vulnerability Button', () => {
    it('should render the Dismiss Vulnerability button', () => {
      expect(vm.$el.querySelector('.js-dismiss-vulnerability')).not.toBeNull();
    });

    it('should trigger the `dismissVulnerability` action when clicked', () => {
      vm.$el.querySelector('.js-dismiss-vulnerability').click();

      expect(actions.dismissVulnerability).toHaveBeenCalledTimes(1);
    });
  });
});
