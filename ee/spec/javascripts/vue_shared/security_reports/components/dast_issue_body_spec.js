import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/dast_issue_body.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('dast issue body', () => {
  let vm;

  const Component = Vue.extend(component);
  const dastIssue = {
    alert: 'X-Content-Type-Options Header Missing',
    severity: 'Low',
    confidence: 'Medium',
    count: '17',
    cweid: '16',
    desc:
      '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff". </p>',
    title: 'X-Content-Type-Options Header Missing',
    reference:
      '<p>http://msdn.microsoft.com/en-us/library/ie/gg622941%28v=vs.85%29.aspx</p><p>https://www.owasp.org/index.php/List_of_useful_HTTP_headers</p>',
    riskcode: '1',
    riskdesc: 'Low (Medium)',
  };
  const status = 'failed';

  afterEach(() => {
    vm.$destroy();
  });

  describe('severity and confidence ', () => {
    it('renders severity and confidence', () => {
      vm = mountComponent(Component, {
        issue: dastIssue,
        issueIndex: 1,
        modalTargetId: '#modal-mrwidget-issue',
        status,
      });

      expect(vm.$el.textContent.trim()).toContain(`${dastIssue.severity} (${dastIssue.confidence})`);
    });
  });

  describe('issue title', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        issue: dastIssue,
        issueIndex: 1,
        modalTargetId: '#modal-mrwidget-issue',
        status,
      });
    });

    it('renders button with issue title', () => {
      expect(vm.$el.textContent.trim()).toContain(dastIssue.title);
    });
  });
});
