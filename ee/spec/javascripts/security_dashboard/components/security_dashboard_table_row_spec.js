import Vue from 'vue';
import component from 'ee/security_dashboard/components/security_dashboard_table_row.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Security Dashboard Table Row', () => {
  let vm;
  let vulnerability;
  const Component = Vue.extend(component);

  afterEach(() => {
    vm.$destroy();
  });

  describe('severity', () => {
    it('should pass high severity down to the component', () => {
      vulnerability = { severity: 'high' };

      vm = mountComponent(Component, { vulnerability });

      expect(vm.severity).toBe(vulnerability.severity);
    });

    it('should compute a `–` when no severity is passed', () => {
      vulnerability = {};

      vm = mountComponent(Component, { vulnerability });

      expect(vm.severity).toBe('–');
    });
  });

  describe('description', () => {
    it('should pass high confidence down to the component', () => {
      vulnerability = { description: 'high' };

      vm = mountComponent(Component, { vulnerability });

      expect(vm.description).toBe(vulnerability.description);
    });
  });

  describe('project namespace', () => {
    it('should get the project namespace from the vulnerability', () => {
      vulnerability = {
        project: { name_with_namespace: 'project name' },
      };

      vm = mountComponent(Component, { vulnerability });

      expect(vm.projectNamespace).toBe(vulnerability.project.name_with_namespace);
    });

    it('should return null when no namespace is set', () => {
      vulnerability = { project: {} };

      vm = mountComponent(Component, { vulnerability });

      expect(vm.projectNamespace).toBeNull();
    });

    it('should return null when no project is set', () => {
      vulnerability = {};

      vm = mountComponent(Component, { vulnerability });

      expect(vm.projectNamespace).toBeNull();
    });
  });

  describe('confidence', () => {
    it('should pass high confidence down to the component', () => {
      vulnerability = { confidence: 'high' };

      vm = mountComponent(Component, { vulnerability });

      expect(vm.confidence).toBe(vulnerability.confidence);
    });

    it('should compute a `–` when no confidence is passed', () => {
      vulnerability = {};

      vm = mountComponent(Component, { vulnerability });

      expect(vm.confidence).toBe('–');
    });
  });

  describe('rendered output', () => {
    beforeEach(() => {
      vulnerability = {
        project: { name_with_namespace: 'project name' },
        confidence: 'high',
        description: 'this is a description',
        severity: 'low',
      };

      vm = mountComponent(Component, { vulnerability });
    });

    it('should render the severity', () => {
      expect(vm.$el.querySelectorAll('.table-mobile-content')[0].textContent)
        .toContain(vulnerability.severity);
    });

    it('should render the description', () => {
      expect(vm.$el.querySelectorAll('.table-mobile-content')[1].textContent)
        .toContain(vulnerability.description);
    });

    it('should render the project namespace', () => {
      expect(vm.$el.querySelectorAll('.table-mobile-content')[1].textContent)
        .toContain(vulnerability.project.name_with_namespace);
    });

    it('should render the confidence', () => {
      expect(vm.$el.querySelectorAll('.table-mobile-content')[2].textContent)
        .toContain(vulnerability.confidence);
    });
  });
});
