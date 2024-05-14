import Vue from 'vue';
import { GlDisclosureDropdown } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import api from '~/api';
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
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  describe('with data', () => {
    beforeEach(async () => {
      jest.spyOn(api, 'trackRedisCounterEvent').mockImplementation(() => {});
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
      artifactName       | downloadPath
      ${'sam_scan'}      | ${'/root/security-reports/-/jobs/14/artifacts/download?file_type=sast'}
      ${'sast-spotbugs'} | ${'/root/security-reports/-/jobs/11/artifacts/download?file_type=sast'}
      ${'sast-eslint'}   | ${'/root/security-reports/-/jobs/8/artifacts/download?file_type=sast'}
      ${'secrets'}       | ${'/root/security-reports/-/jobs/7/artifacts/download?file_type=secret_detection'}
    `(
      'has a dropdown item to download $artifactName artifacts',
      ({ artifactName, downloadPath }) => {
        expect(findDropdown().exists()).toBe(true);

        expect(findDropdown().props('items')).toEqual(
          expect.arrayContaining([
            {
              href: downloadPath,
              text: `Download ${artifactName}`,
              extraAttrs: {
                download: '',
                rel: 'nofollow',
              },
            },
          ]),
        );
      },
    );

    it.each`
      artifactName       | downloadPath
      ${'sast-sobelow'}  | ${''}
      ${'sast-pmd-apex'} | ${''}
    `(
      'does not have a dropdown item to download $artifactName artifacts',
      ({ artifactName, downloadPath }) => {
        expect(findDropdown().exists()).toBe(true);

        expect(findDropdown().props('items')).not.toEqual(
          expect.arrayContaining([
            {
              href: downloadPath,
              text: `Download ${artifactName}`,
              extraAttrs: {
                download: '',
                rel: 'nofollow',
              },
            },
          ]),
        );
      },
    );
  });

  describe('without data', () => {
    beforeEach(() => {
      jest.spyOn(api, 'trackRedisCounterEvent').mockImplementation(() => {});
      createComponent({ mockResponse: { data: { project: { id: 'project-id' } } } });
    });

    it('does not render the widget', () => {
      expect(wrapper.html()).toBe('');
      expect(findDropdown().exists()).toBe(false);
    });
  });
});
