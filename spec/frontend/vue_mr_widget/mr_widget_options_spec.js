import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { securityReportMergeRequestDownloadPathsQueryResponse } from 'jest/vue_shared/security_reports/mock_data';
import axios from '~/lib/utils/axios_utils';
import { setFaviconOverlay } from '~/lib/utils/favicon';
import notify from '~/lib/utils/notify';
import SmartInterval from '~/smart_interval';
import { SUCCESS } from '~/vue_merge_request_widget/components/deployment/constants';
import eventHub from '~/vue_merge_request_widget/event_hub';
import MrWidgetOptions from '~/vue_merge_request_widget/mr_widget_options.vue';
import { stateKey } from '~/vue_merge_request_widget/stores/state_maps';
import securityReportMergeRequestDownloadPathsQuery from '~/vue_shared/security_reports/queries/security_report_merge_request_download_paths.query.graphql';
import { faviconDataUrl, overlayDataUrl } from '../lib/utils/mock_data';
import mockData from './mock_data';

jest.mock('~/smart_interval');

jest.mock('~/lib/utils/favicon');

Vue.use(VueApollo);

describe('MrWidgetOptions', () => {
  let wrapper;
  let mock;

  const COLLABORATION_MESSAGE = 'Members who can merge are allowed to add commits';

  beforeEach(() => {
    gl.mrWidgetData = { ...mockData };
    gon.features = { asyncMrWidget: true };

    mock = new MockAdapter(axios);
    mock.onGet(mockData.merge_request_widget_path).reply(() => [200, { ...mockData }]);
    mock.onGet(mockData.merge_request_cached_widget_path).reply(() => [200, { ...mockData }]);
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
    wrapper = null;

    gl.mrWidgetData = {};
    gon.features = {};
  });

  const createComponent = (mrData = mockData, options = {}) => {
    if (wrapper) {
      wrapper.destroy();
    }

    wrapper = mount(MrWidgetOptions, {
      propsData: {
        mrData: { ...mrData },
      },
      ...options,
    });

    return axios.waitForAll();
  };

  const findSuggestPipeline = () => wrapper.find('[data-testid="mr-suggest-pipeline"]');
  const findSuggestPipelineButton = () => findSuggestPipeline().find('button');
  const findSecurityMrWidget = () => wrapper.find('[data-testid="security-mr-widget"]');

  describe('default', () => {
    beforeEach(() => {
      jest.spyOn(document, 'dispatchEvent');
      return createComponent();
    });

    describe('data', () => {
      it('should instantiate Store and Service', () => {
        expect(wrapper.vm.mr).toBeDefined();
        expect(wrapper.vm.service).toBeDefined();
      });
    });

    describe('computed', () => {
      describe('componentName', () => {
        it('should return merged component', () => {
          expect(wrapper.vm.componentName).toEqual('mr-widget-merged');
        });

        it('should return conflicts component', () => {
          wrapper.vm.mr.state = 'conflicts';

          expect(wrapper.vm.componentName).toEqual('mr-widget-conflicts');
        });
      });

      describe('shouldRenderPipelines', () => {
        it('should return true when hasCI is true', () => {
          wrapper.vm.mr.hasCI = true;

          expect(wrapper.vm.shouldRenderPipelines).toBeTruthy();
        });

        it('should return false when hasCI is false', () => {
          wrapper.vm.mr.hasCI = false;

          expect(wrapper.vm.shouldRenderPipelines).toBeFalsy();
        });
      });

      describe('shouldRenderRelatedLinks', () => {
        it('should return false for the initial data', () => {
          expect(wrapper.vm.shouldRenderRelatedLinks).toBeFalsy();
        });

        it('should return true if there is relatedLinks in MR', () => {
          Vue.set(wrapper.vm.mr, 'relatedLinks', {});

          expect(wrapper.vm.shouldRenderRelatedLinks).toBeTruthy();
        });
      });

      describe('shouldRenderSourceBranchRemovalStatus', () => {
        beforeEach(() => {
          wrapper.vm.mr.state = 'readyToMerge';
        });

        it('should return true when cannot remove source branch and branch will be removed', () => {
          wrapper.vm.mr.canRemoveSourceBranch = false;
          wrapper.vm.mr.shouldRemoveSourceBranch = true;

          expect(wrapper.vm.shouldRenderSourceBranchRemovalStatus).toEqual(true);
        });

        it('should return false when can remove source branch and branch will be removed', () => {
          wrapper.vm.mr.canRemoveSourceBranch = true;
          wrapper.vm.mr.shouldRemoveSourceBranch = true;

          expect(wrapper.vm.shouldRenderSourceBranchRemovalStatus).toEqual(false);
        });

        it('should return false when cannot remove source branch and branch will not be removed', () => {
          wrapper.vm.mr.canRemoveSourceBranch = false;
          wrapper.vm.mr.shouldRemoveSourceBranch = false;

          expect(wrapper.vm.shouldRenderSourceBranchRemovalStatus).toEqual(false);
        });

        it('should return false when in merged state', () => {
          wrapper.vm.mr.canRemoveSourceBranch = false;
          wrapper.vm.mr.shouldRemoveSourceBranch = true;
          wrapper.vm.mr.state = 'merged';

          expect(wrapper.vm.shouldRenderSourceBranchRemovalStatus).toEqual(false);
        });

        it('should return false when in nothing to merge state', () => {
          wrapper.vm.mr.canRemoveSourceBranch = false;
          wrapper.vm.mr.shouldRemoveSourceBranch = true;
          wrapper.vm.mr.state = 'nothingToMerge';

          expect(wrapper.vm.shouldRenderSourceBranchRemovalStatus).toEqual(false);
        });
      });

      describe('shouldRenderCollaborationStatus', () => {
        describe('when collaboration is allowed', () => {
          beforeEach(() => {
            wrapper.vm.mr.allowCollaboration = true;
          });

          describe('when merge request is opened', () => {
            beforeEach((done) => {
              wrapper.vm.mr.isOpen = true;
              nextTick(done);
            });

            it('should render collaboration status', () => {
              expect(wrapper.text()).toContain(COLLABORATION_MESSAGE);
            });
          });

          describe('when merge request is not opened', () => {
            beforeEach((done) => {
              wrapper.vm.mr.isOpen = false;
              nextTick(done);
            });

            it('should not render collaboration status', () => {
              expect(wrapper.text()).not.toContain(COLLABORATION_MESSAGE);
            });
          });
        });

        describe('when collaboration is not allowed', () => {
          beforeEach(() => {
            wrapper.vm.mr.allowCollaboration = false;
          });

          describe('when merge request is opened', () => {
            beforeEach((done) => {
              wrapper.vm.mr.isOpen = true;
              nextTick(done);
            });

            it('should not render collaboration status', () => {
              expect(wrapper.text()).not.toContain(COLLABORATION_MESSAGE);
            });
          });
        });
      });

      describe('showMergePipelineForkWarning', () => {
        describe('when the source project and target project are the same', () => {
          beforeEach((done) => {
            Vue.set(wrapper.vm.mr, 'mergePipelinesEnabled', true);
            Vue.set(wrapper.vm.mr, 'sourceProjectId', 1);
            Vue.set(wrapper.vm.mr, 'targetProjectId', 1);
            nextTick(done);
          });

          it('should be false', () => {
            expect(wrapper.vm.showMergePipelineForkWarning).toEqual(false);
          });
        });

        describe('when merge pipelines are not enabled', () => {
          beforeEach((done) => {
            Vue.set(wrapper.vm.mr, 'mergePipelinesEnabled', false);
            Vue.set(wrapper.vm.mr, 'sourceProjectId', 1);
            Vue.set(wrapper.vm.mr, 'targetProjectId', 2);
            nextTick(done);
          });

          it('should be false', () => {
            expect(wrapper.vm.showMergePipelineForkWarning).toEqual(false);
          });
        });

        describe('when merge pipelines are enabled _and_ the source project and target project are different', () => {
          beforeEach((done) => {
            Vue.set(wrapper.vm.mr, 'mergePipelinesEnabled', true);
            Vue.set(wrapper.vm.mr, 'sourceProjectId', 1);
            Vue.set(wrapper.vm.mr, 'targetProjectId', 2);
            nextTick(done);
          });

          it('should be true', () => {
            expect(wrapper.vm.showMergePipelineForkWarning).toEqual(true);
          });
        });
      });

      describe('formattedHumanAccess', () => {
        it('when user is a tool admin but not a member of project', () => {
          wrapper.vm.mr.humanAccess = null;

          expect(wrapper.vm.formattedHumanAccess).toEqual('');
        });

        it('when user a member of the project', () => {
          wrapper.vm.mr.humanAccess = 'Owner';

          expect(wrapper.vm.formattedHumanAccess).toEqual('owner');
        });
      });
    });

    describe('methods', () => {
      describe('checkStatus', () => {
        let cb;
        let isCbExecuted;

        beforeEach(() => {
          jest.spyOn(wrapper.vm.service, 'checkStatus').mockResolvedValue({ data: mockData });
          jest.spyOn(wrapper.vm.mr, 'setData').mockImplementation(() => {});
          jest.spyOn(wrapper.vm, 'handleNotification').mockImplementation(() => {});

          isCbExecuted = false;
          cb = () => {
            isCbExecuted = true;
          };
        });

        it('should tell service to check status if document is visible', () => {
          wrapper.vm.checkStatus(cb);

          return nextTick().then(() => {
            expect(wrapper.vm.service.checkStatus).toHaveBeenCalled();
            expect(wrapper.vm.mr.setData).toHaveBeenCalled();
            expect(wrapper.vm.handleNotification).toHaveBeenCalledWith(mockData);
            expect(isCbExecuted).toBeTruthy();
          });
        });
      });

      describe('initPolling', () => {
        it('should call SmartInterval', () => {
          wrapper.vm.initPolling();

          expect(SmartInterval).toHaveBeenCalledWith(
            expect.objectContaining({
              callback: wrapper.vm.checkStatus,
            }),
          );
        });
      });

      describe('initDeploymentsPolling', () => {
        it('should call SmartInterval', () => {
          wrapper.vm.initDeploymentsPolling();

          expect(SmartInterval).toHaveBeenCalledWith(
            expect.objectContaining({
              callback: wrapper.vm.fetchPreMergeDeployments,
            }),
          );
        });
      });

      describe('fetchDeployments', () => {
        it('should fetch deployments', () => {
          jest
            .spyOn(wrapper.vm.service, 'fetchDeployments')
            .mockResolvedValue({ data: [{ id: 1, status: SUCCESS }] });

          wrapper.vm.fetchPreMergeDeployments();

          return nextTick().then(() => {
            expect(wrapper.vm.service.fetchDeployments).toHaveBeenCalled();
            expect(wrapper.vm.mr.deployments.length).toEqual(1);
            expect(wrapper.vm.mr.deployments[0].id).toBe(1);
          });
        });
      });

      describe('fetchActionsContent', () => {
        it('should fetch content of Cherry Pick and Revert modals', () => {
          jest
            .spyOn(wrapper.vm.service, 'fetchMergeActionsContent')
            .mockResolvedValue({ data: 'hello world' });

          wrapper.vm.fetchActionsContent();

          return nextTick().then(() => {
            expect(wrapper.vm.service.fetchMergeActionsContent).toHaveBeenCalled();
            expect(document.body.textContent).toContain('hello world');
            expect(document.dispatchEvent).toHaveBeenCalledWith(
              new CustomEvent('merged:UpdateActions'),
            );
          });
        });
      });

      describe('bindEventHubListeners', () => {
        it.each`
          event                        | method                   | methodArgs
          ${'MRWidgetUpdateRequested'} | ${'checkStatus'}         | ${(x) => [x]}
          ${'MRWidgetRebaseSuccess'}   | ${'checkStatus'}         | ${(x) => [x, true]}
          ${'FetchActionsContent'}     | ${'fetchActionsContent'} | ${() => []}
          ${'EnablePolling'}           | ${'resumePolling'}       | ${() => []}
          ${'DisablePolling'}          | ${'stopPolling'}         | ${() => []}
        `('should bind to $event', ({ event, method, methodArgs }) => {
          jest.spyOn(wrapper.vm, method).mockImplementation();

          const eventArg = {};
          eventHub.$emit(event, eventArg);

          expect(wrapper.vm[method]).toHaveBeenCalledWith(...methodArgs(eventArg));
        });

        it('should bind to SetBranchRemoveFlag', () => {
          expect(wrapper.vm.mr.isRemovingSourceBranch).toBe(false);

          eventHub.$emit('SetBranchRemoveFlag', [true]);

          expect(wrapper.vm.mr.isRemovingSourceBranch).toBe(true);
        });

        it('should bind to FailedToMerge', () => {
          wrapper.vm.mr.state = '';
          wrapper.vm.mr.mergeError = '';

          const mergeError = 'Something bad happened!';
          eventHub.$emit('FailedToMerge', mergeError);

          expect(wrapper.vm.mr.state).toBe('failedToMerge');
          expect(wrapper.vm.mr.mergeError).toBe(mergeError);
        });

        it('should bind to UpdateWidgetData', () => {
          jest.spyOn(wrapper.vm.mr, 'setData').mockImplementation();

          const data = { ...mockData };
          eventHub.$emit('UpdateWidgetData', data);

          expect(wrapper.vm.mr.setData).toHaveBeenCalledWith(data);
        });
      });

      describe('setFavicon', () => {
        let faviconElement;

        beforeEach(() => {
          const favicon = document.createElement('link');
          favicon.setAttribute('id', 'favicon');
          favicon.setAttribute('data-original-href', faviconDataUrl);
          document.body.appendChild(favicon);

          faviconElement = document.getElementById('favicon');
        });

        afterEach(() => {
          document.body.removeChild(document.getElementById('favicon'));
        });

        it('should call setFavicon method', async () => {
          wrapper.vm.mr.ciStatusFaviconPath = overlayDataUrl;

          await wrapper.vm.setFaviconHelper();

          expect(setFaviconOverlay).toHaveBeenCalledWith(overlayDataUrl);
        });

        it('should not call setFavicon when there is no ciStatusFaviconPath', (done) => {
          wrapper.vm.mr.ciStatusFaviconPath = null;
          wrapper.vm
            .setFaviconHelper()
            .then(() => {
              expect(faviconElement.getAttribute('href')).toEqual(null);
              done();
            })
            .catch(done.fail);
        });
      });

      describe('handleNotification', () => {
        const data = {
          ci_status: 'running',
          title: 'title',
          pipeline: { details: { status: { label: 'running-label' } } },
        };

        beforeEach(() => {
          jest.spyOn(notify, 'notifyMe').mockImplementation(() => {});

          wrapper.vm.mr.ciStatus = 'failed';
          wrapper.vm.mr.gitlabLogo = 'logo.png';
        });

        it('should call notifyMe', () => {
          wrapper.vm.handleNotification(data);

          expect(notify.notifyMe).toHaveBeenCalledWith(
            'Pipeline running-label',
            'Pipeline running-label for "title"',
            'logo.png',
          );
        });

        it('should not call notifyMe if the status has not changed', () => {
          wrapper.vm.mr.ciStatus = data.ci_status;

          wrapper.vm.handleNotification(data);

          expect(notify.notifyMe).not.toHaveBeenCalled();
        });

        it('should not notify if no pipeline provided', () => {
          wrapper.vm.handleNotification({
            ...data,
            pipeline: undefined,
          });

          expect(notify.notifyMe).not.toHaveBeenCalled();
        });
      });

      describe('resumePolling', () => {
        it('should call stopTimer on pollingInterval', () => {
          jest.spyOn(wrapper.vm.pollingInterval, 'resume').mockImplementation(() => {});

          wrapper.vm.resumePolling();

          expect(wrapper.vm.pollingInterval.resume).toHaveBeenCalled();
        });
      });

      describe('stopPolling', () => {
        it('should call stopTimer on pollingInterval', () => {
          jest.spyOn(wrapper.vm.pollingInterval, 'stopTimer').mockImplementation(() => {});

          wrapper.vm.stopPolling();

          expect(wrapper.vm.pollingInterval.stopTimer).toHaveBeenCalled();
        });
      });
    });

    describe('rendering relatedLinks', () => {
      beforeEach(() => {
        createComponent({
          ...mockData,
          issues_links: {
            closing: `
              <a class="close-related-link" href="#">
                Close
              </a>
            `,
          },
        });

        return nextTick();
      });

      it('renders if there are relatedLinks', () => {
        expect(wrapper.find('.close-related-link').exists()).toBe(true);
      });

      it('does not render if state is nothingToMerge', (done) => {
        wrapper.vm.mr.state = stateKey.nothingToMerge;
        nextTick(() => {
          expect(wrapper.find('.close-related-link').exists()).toBe(false);
          done();
        });
      });
    });

    describe('rendering source branch removal status', () => {
      it('renders when user cannot remove branch and branch should be removed', (done) => {
        wrapper.vm.mr.canRemoveSourceBranch = false;
        wrapper.vm.mr.shouldRemoveSourceBranch = true;
        wrapper.vm.mr.state = 'readyToMerge';

        nextTick(() => {
          const tooltip = wrapper.find('[data-testid="question-o-icon"]');

          expect(wrapper.text()).toContain('The source branch will be deleted');
          expect(tooltip.attributes('title')).toBe(
            'A user with write access to the source branch selected this option',
          );

          done();
        });
      });

      it('does not render in merged state', (done) => {
        wrapper.vm.mr.canRemoveSourceBranch = false;
        wrapper.vm.mr.shouldRemoveSourceBranch = true;
        wrapper.vm.mr.state = 'merged';

        nextTick(() => {
          expect(wrapper.text()).toContain('The source branch has been deleted');
          expect(wrapper.text()).not.toContain('The source branch will be deleted');

          done();
        });
      });
    });

    describe('rendering deployments', () => {
      const changes = [
        {
          path: 'index.html',
          external_url: 'http://root-main-patch-91341.volatile-watch.surge.sh/index.html',
        },
        {
          path: 'imgs/gallery.html',
          external_url: 'http://root-main-patch-91341.volatile-watch.surge.sh/imgs/gallery.html',
        },
        {
          path: 'about/',
          external_url: 'http://root-main-patch-91341.volatile-watch.surge.sh/about/',
        },
      ];
      const deploymentMockData = {
        id: 15,
        name: 'review/diplo',
        url: '/root/acets-review-apps/environments/15',
        stop_url: '/root/acets-review-apps/environments/15/stop',
        metrics_url: '/root/acets-review-apps/environments/15/deployments/1/metrics',
        metrics_monitoring_url: '/root/acets-review-apps/environments/15/metrics',
        external_url: 'http://diplo.',
        external_url_formatted: 'diplo.',
        deployed_at: '2017-03-22T22:44:42.258Z',
        deployed_at_formatted: 'Mar 22, 2017 10:44pm',
        changes,
        status: SUCCESS,
      };

      beforeEach((done) => {
        wrapper.vm.mr.deployments.push(
          {
            ...deploymentMockData,
          },
          {
            ...deploymentMockData,
            id: deploymentMockData.id + 1,
          },
        );

        nextTick(done);
      });

      it('renders multiple deployments', () => {
        expect(wrapper.findAll('.deploy-heading').length).toBe(2);
      });

      it('renders dropdpown with multiple file changes', () => {
        expect(
          wrapper.find('.js-mr-wigdet-deployment-dropdown').findAll('.js-filtered-dropdown-result')
            .length,
        ).toEqual(changes.length);
      });
    });

    describe('code quality widget', () => {
      it('renders the component', () => {
        expect(wrapper.find('.js-codequality-widget').exists()).toBe(true);
      });
    });

    describe('pipeline for target branch after merge', () => {
      describe('with information for target branch pipeline', () => {
        beforeEach((done) => {
          wrapper.vm.mr.state = 'merged';
          wrapper.vm.mr.mergePipeline = {
            id: 127,
            user: {
              id: 1,
              name: 'Administrator',
              username: 'root',
              state: 'active',
              avatar_url: null,
              web_url: 'http://localhost:3000/root',
              status_tooltip_html: null,
              path: '/root',
            },
            active: true,
            coverage: null,
            source: 'push',
            created_at: '2018-10-22T11:41:35.186Z',
            updated_at: '2018-10-22T11:41:35.433Z',
            path: '/root/ci-web-terminal/pipelines/127',
            flags: {
              latest: true,
              stuck: true,
              auto_devops: false,
              yaml_errors: false,
              retryable: false,
              cancelable: true,
              failure_reason: false,
            },
            details: {
              status: {
                icon: 'status_pending',
                text: 'pending',
                label: 'pending',
                group: 'pending',
                tooltip: 'pending',
                has_details: true,
                details_path: '/root/ci-web-terminal/pipelines/127',
                illustration: null,
                favicon:
                  '/assets/ci_favicons/favicon_status_pending-5bdf338420e5221ca24353b6bff1c9367189588750632e9a871b7af09ff6a2ae.png',
              },
              duration: null,
              finished_at: null,
              stages: [
                {
                  name: 'test',
                  title: 'test: pending',
                  status: {
                    icon: 'status_pending',
                    text: 'pending',
                    label: 'pending',
                    group: 'pending',
                    tooltip: 'pending',
                    has_details: true,
                    details_path: '/root/ci-web-terminal/pipelines/127#test',
                    illustration: null,
                    favicon:
                      '/assets/ci_favicons/favicon_status_pending-5bdf338420e5221ca24353b6bff1c9367189588750632e9a871b7af09ff6a2ae.png',
                  },
                  path: '/root/ci-web-terminal/pipelines/127#test',
                  dropdown_path: '/root/ci-web-terminal/pipelines/127/stage.json?stage=test',
                },
              ],
              artifacts: [],
              manual_actions: [],
              scheduled_actions: [],
            },
            ref: {
              name: 'main',
              path: '/root/ci-web-terminal/commits/main',
              tag: false,
              branch: true,
            },
            commit: {
              id: 'aa1939133d373c94879becb79d91828a892ee319',
              short_id: 'aa193913',
              title: "Merge branch 'main-test' into 'main'",
              created_at: '2018-10-22T11:41:33.000Z',
              parent_ids: [
                '4622f4dd792468993003caf2e3be978798cbe096',
                '76598df914cdfe87132d0c3c40f80db9fa9396a4',
              ],
              message:
                "Merge branch 'main-test' into 'main'\n\nUpdate .gitlab-ci.yml\n\nSee merge request root/ci-web-terminal!1",
              author_name: 'Administrator',
              author_email: 'admin@example.com',
              authored_date: '2018-10-22T11:41:33.000Z',
              committer_name: 'Administrator',
              committer_email: 'admin@example.com',
              committed_date: '2018-10-22T11:41:33.000Z',
              author: {
                id: 1,
                name: 'Administrator',
                username: 'root',
                state: 'active',
                avatar_url: null,
                web_url: 'http://localhost:3000/root',
                status_tooltip_html: null,
                path: '/root',
              },
              author_gravatar_url: null,
              commit_url:
                'http://localhost:3000/root/ci-web-terminal/commit/aa1939133d373c94879becb79d91828a892ee319',
              commit_path: '/root/ci-web-terminal/commit/aa1939133d373c94879becb79d91828a892ee319',
            },
            cancel_path: '/root/ci-web-terminal/pipelines/127/cancel',
          };
          nextTick(done);
        });

        it('renders pipeline block', () => {
          expect(wrapper.find('.js-post-merge-pipeline').exists()).toBe(true);
        });

        describe('with post merge deployments', () => {
          beforeEach((done) => {
            wrapper.vm.mr.postMergeDeployments = [
              {
                id: 15,
                name: 'review/diplo',
                url: '/root/acets-review-apps/environments/15',
                stop_url: '/root/acets-review-apps/environments/15/stop',
                metrics_url: '/root/acets-review-apps/environments/15/deployments/1/metrics',
                metrics_monitoring_url: '/root/acets-review-apps/environments/15/metrics',
                external_url: 'http://diplo.',
                external_url_formatted: 'diplo.',
                deployed_at: '2017-03-22T22:44:42.258Z',
                deployed_at_formatted: 'Mar 22, 2017 10:44pm',
                changes: [
                  {
                    path: 'index.html',
                    external_url: 'http://root-main-patch-91341.volatile-watch.surge.sh/index.html',
                  },
                  {
                    path: 'imgs/gallery.html',
                    external_url:
                      'http://root-main-patch-91341.volatile-watch.surge.sh/imgs/gallery.html',
                  },
                  {
                    path: 'about/',
                    external_url: 'http://root-main-patch-91341.volatile-watch.surge.sh/about/',
                  },
                ],
                status: 'success',
              },
            ];

            nextTick(done);
          });

          it('renders post deployment information', () => {
            expect(wrapper.find('.js-post-deployment').exists()).toBe(true);
          });
        });
      });

      describe('without information for target branch pipeline', () => {
        beforeEach((done) => {
          wrapper.vm.mr.state = 'merged';

          nextTick(done);
        });

        it('does not render pipeline block', () => {
          expect(wrapper.find('.js-post-merge-pipeline').exists()).toBe(false);
        });
      });

      describe('when state is not merged', () => {
        beforeEach((done) => {
          wrapper.vm.mr.state = 'archived';

          nextTick(done);
        });

        it('does not render pipeline block', () => {
          expect(wrapper.find('.js-post-merge-pipeline').exists()).toBe(false);
        });

        it('does not render post deployment information', () => {
          expect(wrapper.find('.js-post-deployment').exists()).toBe(false);
        });
      });
    });

    it('should not suggest pipelines when feature flag is not present', () => {
      expect(findSuggestPipeline().exists()).toBe(false);
    });
  });

  describe('security widget', () => {
    describe.each`
      context                  | hasPipeline | shouldRender
      ${'there is a pipeline'} | ${true}     | ${true}
      ${'no pipeline'}         | ${false}    | ${false}
    `('given $context', ({ hasPipeline, shouldRender }) => {
      beforeEach(() => {
        const mrData = {
          ...mockData,
          ...(hasPipeline ? {} : { pipeline: null }),
        };

        // Override top-level mocked requests, which always use a fresh copy of
        // mockData, which always includes the full pipeline object.
        mock.onGet(mockData.merge_request_widget_path).reply(() => [200, mrData]);
        mock.onGet(mockData.merge_request_cached_widget_path).reply(() => [200, mrData]);

        return createComponent(mrData, {
          apolloProvider: createMockApollo([
            [
              securityReportMergeRequestDownloadPathsQuery,
              async () => ({ data: securityReportMergeRequestDownloadPathsQueryResponse }),
            ],
          ]),
        });
      });

      it(shouldRender ? 'renders' : 'does not render', () => {
        expect(findSecurityMrWidget().exists()).toBe(shouldRender);
      });
    });
  });

  describe('suggestPipeline', () => {
    beforeEach(() => {
      mock.onAny().reply(200);
    });

    describe('given feature flag is enabled', () => {
      beforeEach(() => {
        createComponent();

        wrapper.vm.mr.hasCI = false;
      });

      it('should suggest pipelines when none exist', () => {
        expect(findSuggestPipeline().exists()).toBe(true);
      });

      it.each([
        { isDismissedSuggestPipeline: true },
        { mergeRequestAddCiConfigPath: null },
        { hasCI: true },
      ])('with %s, should not suggest pipeline', async (obj) => {
        Object.assign(wrapper.vm.mr, obj);

        await nextTick();

        expect(findSuggestPipeline().exists()).toBe(false);
      });

      it('should allow dismiss of the suggest pipeline message', async () => {
        await findSuggestPipelineButton().trigger('click');

        expect(findSuggestPipeline().exists()).toBe(false);
      });
    });
  });
});
