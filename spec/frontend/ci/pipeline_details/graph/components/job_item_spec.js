import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import { GlModal, GlToast } from '@gitlab/ui';
import JobItem from '~/ci/pipeline_details/graph/components/job_item.vue';
import axios from '~/lib/utils/axios_utils';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import ActionComponent from '~/ci/common/private/job_action_component.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  delayedJob,
  mockJob,
  mockJobWithoutDetails,
  mockJobWithUnauthorizedAction,
  mockFailedJob,
  triggerJob,
  triggerJobWithRetryAction,
} from '../mock_data';

describe('pipeline graph job item', () => {
  useLocalStorageSpy();
  Vue.use(GlToast);

  let wrapper;
  let mockAxios;

  const findJobWithoutLink = () => wrapper.findByTestId('job-without-link');
  const findJobWithLink = () => wrapper.findByTestId('job-with-link');
  const findActionVueComponent = () => wrapper.findComponent(ActionComponent);
  const findActionComponent = () => wrapper.findByTestId('ci-action-button');
  const findBadge = () => wrapper.findByTestId('job-bridge-badge');
  const findJobLink = () => wrapper.findByTestId('job-with-link');
  const findJobCiIcon = () => wrapper.findComponent(CiIcon);
  const findModal = () => wrapper.findComponent(GlModal);

  const clickOnModalPrimaryBtn = () => findModal().vm.$emit('primary');
  const clickOnModalCancelBtn = () => findModal().vm.$emit('hide');
  const clickOnModalCloseBtn = () => findModal().vm.$emit('close');

  const myCustomClass1 = 'my-class-1';
  const myCustomClass2 = 'my-class-2';

  const createWrapper = ({ mountFn = mountExtended, props, ...options } = {}) => {
    wrapper = mountFn(JobItem, {
      propsData: {
        job: mockJob,
        ...props,
      },
      stubs: {
        CiIcon,
      },
      ...options,
    });
  };

  const triggerActiveClass = 'gl-shadow-x0-y0-b3-s1-blue-500';

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('name with link', () => {
    it('should render the job name and status with a link', async () => {
      createWrapper();

      await nextTick();
      const link = findJobLink();

      expect(link.attributes('href')).toBe(mockJob.status.detailsPath);

      expect(link.attributes('title')).toBe(`${mockJob.name} - ${mockJob.status.label}`);

      expect(findJobCiIcon().exists()).toBe(true);
      expect(findJobCiIcon().find('[data-testid="status_success_borderless-icon"]').exists()).toBe(
        true,
      );

      expect(wrapper.text()).toBe(mockJob.name);
    });
  });

  describe('name without link', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          job: mockJobWithoutDetails,
          cssClassJobName: 'css-class-job-name',
          jobHovered: 'test',
        },
      });
    });

    it('should render status and name', () => {
      expect(findJobCiIcon().exists()).toBe(true);
      expect(findJobCiIcon().find('[data-testid="status_success_borderless-icon"]').exists()).toBe(
        true,
      );
      expect(findJobLink().exists()).toBe(false);

      expect(wrapper.text()).toBe(mockJobWithoutDetails.name);
    });

    it('should apply hover class and provided class name', () => {
      expect(findJobWithoutLink().classes()).toContain('css-class-job-name');
    });
  });

  describe('name when is-link is false', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          isLink: false,
        },
      });
    });

    it('should render status and name', () => {
      expect(findJobCiIcon().exists()).toBe(true);
      expect(findJobCiIcon().find('[data-testid="status_success_borderless-icon"]').exists()).toBe(
        true,
      );

      expect(wrapper.text()).toBe(mockJob.name);
    });
  });

  describe('CiIcon', () => {
    it('should not render a link', () => {
      createWrapper();

      expect(findJobCiIcon().exists()).toBe(true);
      expect(findJobCiIcon().props('useLink')).toBe(false);
    });
  });

  describe('action icon', () => {
    it('should render the action icon', () => {
      createWrapper();

      const actionComponent = findActionComponent();

      expect(actionComponent.exists()).toBe(true);
      expect(actionComponent.props('actionIcon')).toBe('retry');
      expect(actionComponent.attributes('disabled')).toBeUndefined();
    });

    it('should render disabled action icon when user cannot run the action', () => {
      createWrapper({
        props: {
          job: mockJobWithUnauthorizedAction,
        },
      });

      const actionComponent = findActionComponent();

      expect(actionComponent.exists()).toBe(true);
      expect(actionComponent.props('actionIcon')).toBe('stop');
      expect(actionComponent.attributes('disabled')).toBeDefined();
    });

    it('action icon tooltip text when job has passed but can be ran again', () => {
      createWrapper({ props: { job: mockJob } });

      expect(findActionComponent().props('tooltipText')).toBe('Run again');
    });

    it('action icon tooltip text when job has failed and can be retried', () => {
      createWrapper({ props: { job: mockFailedJob } });

      expect(findActionComponent().props('tooltipText')).toBe('Retry');
    });
  });

  describe('job style', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          job: mockJob,
          cssClassJobName: 'css-class-job-name',
        },
      });
    });

    it('should render provided class name', () => {
      expect(findJobLink().classes()).toContain('css-class-job-name');
    });

    it('does not show a badge on the job item', () => {
      expect(findBadge().exists()).toBe(false);
    });

    it('does not apply the trigger job class', () => {
      expect(findJobWithLink().classes()).not.toContain('gl-rounded-lg');
    });
  });

  describe('status label', () => {
    it('should not render status label when it is not provided', () => {
      createWrapper({
        props: {
          job: {
            id: 4258,
            name: 'test',
            status: {
              icon: 'status_success',
            },
          },
        },
      });

      expect(findJobWithoutLink().attributes('title')).toBe('test');
    });

    it('should not render status label when it is  provided', () => {
      createWrapper({
        props: {
          job: {
            id: 4259,
            name: 'test',
            status: {
              icon: 'status_success',
              label: 'success',
              tooltip: 'success',
            },
          },
        },
      });

      expect(findJobWithoutLink().attributes('title')).toBe('test - success');
    });
  });

  describe('for delayed job', () => {
    it('displays remaining time in tooltip', () => {
      createWrapper({
        props: {
          job: delayedJob,
        },
      });

      expect(findJobWithLink().attributes('title')).toBe(
        `delayed job - delayed manual action (00:00:00)`,
      );
    });
  });

  describe('trigger job', () => {
    describe('card', () => {
      beforeEach(() => {
        createWrapper({
          props: {
            job: triggerJob,
          },
        });
      });

      it('shows a badge on the job item', () => {
        expect(findBadge().exists()).toBe(true);
        expect(findBadge().text()).toBe('Trigger job');
      });

      it('applies a rounded corner style instead of the usual pill shape', () => {
        expect(findJobWithoutLink().classes()).toContain('gl-rounded-lg');
      });
    });

    describe('when retrying', () => {
      const mockToastShow = jest.fn();

      beforeEach(async () => {
        createWrapper({
          mountFn: shallowMountExtended,
          props: {
            skipRetryModal: true,
            job: triggerJobWithRetryAction,
          },
          mocks: {
            $toast: {
              show: mockToastShow,
            },
          },
        });

        await findActionVueComponent().vm.$emit('pipelineActionRequestComplete');
        await nextTick();
      });

      it('shows a toast message that the downstream is being created', () => {
        expect(mockToastShow).toHaveBeenCalledTimes(1);
      });
    });

    describe('highlighting', () => {
      it.each`
        job                      | jobName                       | expanded | link
        ${mockJob}               | ${mockJob.name}               | ${true}  | ${true}
        ${mockJobWithoutDetails} | ${mockJobWithoutDetails.name} | ${true}  | ${false}
      `(
        `trigger job should stay highlighted when downstream is expanded`,
        ({ job, jobName, expanded, link }) => {
          createWrapper({
            props: {
              job,
              pipelineExpanded: { jobName, expanded },
            },
          });
          const findJobEl = link ? findJobWithLink : findJobWithoutLink;

          expect(findJobEl().classes()).toContain(triggerActiveClass);
        },
      );

      it.each`
        job                      | jobName                       | expanded | link
        ${mockJob}               | ${mockJob.name}               | ${false} | ${true}
        ${mockJobWithoutDetails} | ${mockJobWithoutDetails.name} | ${false} | ${false}
      `(
        `trigger job should not be highlighted when downstream is not expanded`,
        ({ job, jobName, expanded, link }) => {
          createWrapper({
            props: {
              job,
              pipelineExpanded: { jobName, expanded },
            },
          });
          const findJobEl = link ? findJobWithLink : findJobWithoutLink;

          expect(findJobEl().classes()).not.toContain(triggerActiveClass);
        },
      );
    });
  });

  describe('job classes', () => {
    it('job class is shown', () => {
      createWrapper({
        props: {
          job: mockJob,
          cssClassJobName: 'my-class',
        },
      });

      const jobLinkEl = findJobLink();

      expect(jobLinkEl.classes()).toContain('my-class');

      expect(jobLinkEl.classes()).not.toContain(triggerActiveClass);
    });

    it('job class is shown, along with hover', () => {
      createWrapper({
        props: {
          job: mockJob,
          cssClassJobName: 'my-class',
          sourceJobHovered: mockJob.name,
        },
      });

      const jobLinkEl = findJobLink();

      expect(jobLinkEl.classes()).toContain('my-class');
      expect(jobLinkEl.classes()).toContain(triggerActiveClass);
    });

    it('multiple job classes are shown', () => {
      createWrapper({
        props: {
          job: mockJob,
          cssClassJobName: [myCustomClass1, myCustomClass2],
        },
      });

      const jobLinkEl = findJobLink();

      expect(jobLinkEl.classes()).toContain(myCustomClass1);
      expect(jobLinkEl.classes()).toContain(myCustomClass2);

      expect(jobLinkEl.classes()).not.toContain(triggerActiveClass);
    });

    it('multiple job classes are shown conditionally', () => {
      createWrapper({
        props: {
          job: mockJob,
          cssClassJobName: { [myCustomClass1]: true, [myCustomClass2]: true },
        },
      });

      const jobLinkEl = findJobLink();

      expect(jobLinkEl.classes()).toContain(myCustomClass1);
      expect(jobLinkEl.classes()).toContain(myCustomClass2);

      expect(jobLinkEl.classes()).not.toContain(triggerActiveClass);
    });

    it('multiple job classes are shown, along with a hover', () => {
      createWrapper({
        props: {
          job: mockJob,
          cssClassJobName: [myCustomClass1, myCustomClass2],
          sourceJobHovered: mockJob.name,
        },
      });

      const jobLinkEl = findJobLink();

      expect(jobLinkEl.classes()).toContain(myCustomClass1);
      expect(jobLinkEl.classes()).toContain(myCustomClass2);
      expect(jobLinkEl.classes()).toContain(triggerActiveClass);
    });
  });

  describe('confirmation modal', () => {
    describe('when clicking on the action component', () => {
      it.each`
        skipRetryModal | exists   | visibilityText
        ${false}       | ${true}  | ${'shows'}
        ${true}        | ${false} | ${'hides'}
      `(
        '$visibilityText the modal when `skipRetryModal` is $skipRetryModal',
        async ({ exists, skipRetryModal }) => {
          createWrapper({
            props: {
              skipRetryModal,
              job: triggerJobWithRetryAction,
            },
          });
          await findActionComponent().trigger('click');

          expect(findModal().exists()).toBe(exists);
        },
      );
    });

    describe('when showing the modal', () => {
      it.each`
        buttonName   | shouldTriggerActionClick | actionBtn
        ${'primary'} | ${true}                  | ${clickOnModalPrimaryBtn}
        ${'cancel'}  | ${false}                 | ${clickOnModalCancelBtn}
        ${'close'}   | ${false}                 | ${clickOnModalCloseBtn}
      `(
        'clicking on $buttonName will pass down shouldTriggerActionClick as $shouldTriggerActionClick to the action component',
        async ({ shouldTriggerActionClick, actionBtn }) => {
          createWrapper({
            props: {
              skipRetryModal: false,
              job: triggerJobWithRetryAction,
            },
          });
          await findActionComponent().trigger('click');

          await actionBtn();

          expect(findActionComponent().props().shouldTriggerClick).toBe(shouldTriggerActionClick);
        },
      );
    });

    describe('when not checking the "do not show this again" checkbox', () => {
      it.each`
        actionName      | actionBtn
        ${'closing'}    | ${clickOnModalCloseBtn}
        ${'cancelling'} | ${clickOnModalCancelBtn}
        ${'confirming'} | ${clickOnModalPrimaryBtn}
      `(
        'does not emit any event and will not modify localstorage on $actionName',
        async ({ actionBtn }) => {
          createWrapper({
            props: {
              skipRetryModal: false,
              job: triggerJobWithRetryAction,
            },
          });
          await findActionComponent().trigger('click');
          await actionBtn();

          expect(wrapper.emitted().setSkipRetryModal).toBeUndefined();
          expect(localStorage.setItem).not.toHaveBeenCalled();
        },
      );
    });

    describe('when checking the "do not show this again" checkbox', () => {
      it.each`
        actionName      | actionBtn
        ${'closing'}    | ${clickOnModalCloseBtn}
        ${'cancelling'} | ${clickOnModalCancelBtn}
        ${'confirming'} | ${clickOnModalPrimaryBtn}
      `(
        'emits "setSkipRetryModal" and set local storage key on $actionName the modal',
        async ({ actionBtn }) => {
          // We are passing the checkbox as a slot to the GlModal.
          // The way GlModal is mounted, we can neither click on the box
          // or emit an event directly. We therefore set the data property
          // as it would be if the box was checked.
          createWrapper({
            data() {
              return {
                currentSkipModalValue: true,
              };
            },
            props: {
              skipRetryModal: false,
              job: triggerJobWithRetryAction,
            },
          });
          await findActionComponent().trigger('click');
          await actionBtn();

          expect(wrapper.emitted().setSkipRetryModal).toHaveLength(1);
          expect(localStorage.setItem).toHaveBeenCalledWith('skip_retry_modal', 'true');
        },
      );
    });
  });
});
