import Vue from 'vue';
import { GlDropdown } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import MRSecurityWidget from '~/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue';
import Widget from '~/vue_merge_request_widget/components/widget/widget.vue';
import securityReportMergeRequestDownloadPathsQuery from '~/vue_merge_request_widget/extensions/security_reports/graphql/security_report_merge_request_download_paths.query.graphql';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockArtifacts } from './mock_data';

Vue.use(VueApollo);

describe('vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue', () => {
  let wrapper;

  const createComponent = ({ propsData, mockResponse = mockArtifacts() } = {}) => {
    wrapper = mountExtended(MRSecurityWidget, {
      apolloProvider: createMockApollo([
        [securityReportMergeRequestDownloadPathsQuery, jest.fn().mockResolvedValue(mockResponse)],
      ]),
      propsData: {
        ...propsData,
        mr: {},
      },
    });
  };

  const findWidget = () => wrapper.findComponent(Widget);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItem = (name) => wrapper.findByTestId(name);

  describe('with data', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('displays the correct message', () => {
      expect(wrapper.findByText('Security scans have run').exists()).toBe(true);
    });

    it('displays the help popover', () => {
      expect(findWidget().props('helpPopover')).toEqual({
        content: {
          learnMorePath:
            '/help/user/application_security/index#view-security-scan-information-in-merge-requests',
          text:
            'New vulnerabilities are vulnerabilities that the security scan detects in the merge request that are different to existing vulnerabilities in the default branch.',
        },
        options: {
          title: 'Security scan results',
        },
      });
    });

    it.each`
      artifactName       | exists   | downloadPath
      ${'sam_scan'}      | ${true}  | ${'/root/security-reports/-/jobs/14/artifacts/download?file_type=sast'}
      ${'sast-spotbugs'} | ${true}  | ${'/root/security-reports/-/jobs/11/artifacts/download?file_type=sast'}
      ${'sast-sobelow'}  | ${false} | ${''}
      ${'sast-pmd-apex'} | ${false} | ${''}
      ${'sast-eslint'}   | ${true}  | ${'/root/security-reports/-/jobs/8/artifacts/download?file_type=sast'}
      ${'secrets'}       | ${true}  | ${'/root/security-reports/-/jobs/7/artifacts/download?file_type=secret_detection'}
    `(
      'has a dropdown to download $artifactName artifacts',
      ({ artifactName, exists, downloadPath }) => {
        expect(findDropdown().exists()).toBe(true);
        expect(wrapper.findByText(`Download ${artifactName}`).exists()).toBe(exists);

        if (exists) {
          const dropdownItem = findDropdownItem(`download-${artifactName}`);
          expect(dropdownItem.attributes('download')).toBe('');
          expect(dropdownItem.attributes('href')).toBe(downloadPath);
        }
      },
    );
  });

  describe('without data', () => {
    beforeEach(() => {
      createComponent({ mockResponse: { data: { project: { id: 'project-id' } } } });
    });

    it('does not render the widget', () => {
      expect(wrapper.html()).toBe('');
      expect(findDropdown().exists()).toBe(false);
    });
  });
});
