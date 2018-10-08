import Vue from 'vue';
import component from 'ee/security_dashboard/components/security_dashboard_table_row.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Security Dashboard Table Row', () => {
  let vm;
  let props;
  const Component = Vue.extend(component);

  afterEach(() => {
    vm.$destroy();
  });

  describe('when loading', () => {
    beforeEach(() => {
      props = { isLoading: true };
      vm = mountComponent(Component, props);
    });

    it('should display the skeleton loader', () => {
      expect(vm.$el.querySelector('.js-skeleton-loader')).not.toBeNull();
    });

    it('should render a ` ` for severity', () => {
      expect(vm.severity).toEqual(' ');
      expect(vm.$el.querySelectorAll('.table-mobile-content')[0].textContent).toContain(' ');
    });

    it('should render a `–` for confidence', () => {
      expect(vm.confidence).toEqual('–');
      expect(vm.$el.querySelectorAll('.table-mobile-content')[2].textContent).toContain('–');
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      const vulnerability = {
        severity: 'high',
        description: 'Test vulnerability',
        confidence: 'medium',
        project: { name_with_namespace: 'project name' },
      };

      props = { vulnerability };
      vm = mountComponent(Component, props);
    });

    it('should not display the skeleton loader', () => {
      expect(vm.$el.querySelector('.js-skeleton-loader')).not.toExist();
    });

    it('should render the severity', () => {
      expect(vm.$el.querySelectorAll('.table-mobile-content')[0].textContent).toContain(
        props.vulnerability.severity,
      );
    });

    it('should render the description', () => {
      expect(vm.$el.querySelectorAll('.table-mobile-content')[1].textContent).toContain(
        props.vulnerability.description,
      );
    });

    it('should render the project namespace', () => {
      expect(vm.$el.querySelectorAll('.table-mobile-content')[1].textContent).toContain(
        props.vulnerability.project.name_with_namespace,
      );
    });

    it('should render the confidence', () => {
      expect(vm.$el.querySelectorAll('.table-mobile-content')[2].textContent).toContain(
        props.vulnerability.confidence,
      );
    });
  });
});
