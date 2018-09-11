import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/sast_container_issue_body.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('sast container issue body', () => {
  let vm;

  const Component = Vue.extend(component);

  const sastContainerIssue = {
    title: 'CVE-2017-11671',
    namespace: 'debian:8',
    path: 'debian:8',
    severity: 'Low',
    vulnerability: 'CVE-2017-11671',
  };

  const status = 'failed';

  afterEach(() => {
    vm.$destroy();
  });

  describe('with severity', () => {
    it('renders severity key', () => {
      vm = mountComponent(Component, {
        issue: sastContainerIssue,
        status,
      });

      expect(vm.$el.textContent.trim()).toContain(sastContainerIssue.severity);
    });
  });

  describe('without severity', () => {
    it('does not render severity key', () => {
      const issueCopy = Object.assign({}, sastContainerIssue);
      delete issueCopy.severity;

      vm = mountComponent(Component, {
        issue: issueCopy,
        status,
      });

      expect(vm.$el.textContent.trim()).not.toContain(sastContainerIssue.severity);
    });
  });

  it('renders name', () => {
    vm = mountComponent(Component, {
      issue: sastContainerIssue,
      status,
    });

    expect(vm.$el.querySelector('button').textContent.trim()).toEqual(sastContainerIssue.title);
  });

  describe('path', () => {
    it('renders path', () => {
      vm = mountComponent(Component, {
        issue: sastContainerIssue,
        status,
      });

      expect(vm.$el.textContent.trim()).toContain(sastContainerIssue.path);
    });
  });
});
