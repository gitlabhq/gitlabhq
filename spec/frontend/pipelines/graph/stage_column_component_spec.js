import { mount, shallowMount } from '@vue/test-utils';
import ActionComponent from '~/pipelines/components/graph/action_component.vue';
import StageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';

const mockJob = {
  id: 4250,
  name: 'test',
  status: {
    icon: 'status_success',
    text: 'passed',
    label: 'passed',
    group: 'success',
    details_path: '/root/ci-mock/builds/4250',
    action: {
      icon: 'retry',
      title: 'Retry',
      path: '/root/ci-mock/builds/4250/retry',
      method: 'post',
    },
  },
};

const mockGroups = Array(4)
  .fill(0)
  .map((item, idx) => {
    return { ...mockJob, id: idx, name: `fish-${idx}` };
  });

const defaultProps = {
  title: 'Fish',
  groups: mockGroups,
};

describe('stage column component', () => {
  let wrapper;

  const findStageColumnTitle = () => wrapper.find('[data-testid="stage-column-title"]');
  const findStageColumnGroup = () => wrapper.find('[data-testid="stage-column-group"]');
  const findAllStageColumnGroups = () => wrapper.findAll('[data-testid="stage-column-group"]');
  const findActionComponent = () => wrapper.find(ActionComponent);

  const createComponent = ({ method = shallowMount, props = {} } = {}) => {
    wrapper = method(StageColumnComponent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent({ method: mount });
    });

    it('should render provided title', () => {
      expect(findStageColumnTitle().text()).toBe(defaultProps.title);
    });

    it('should render the provided groups', () => {
      expect(findAllStageColumnGroups().length).toBe(mockGroups.length);
    });
  });

  describe('job', () => {
    beforeEach(() => {
      createComponent({
        method: mount,
        props: {
          groups: [
            {
              id: 4259,
              name: '<img src=x onerror=alert(document.domain)>',
              status: {
                icon: 'status_success',
                label: 'success',
                tooltip: '<img src=x onerror=alert(document.domain)>',
              },
            },
          ],
          title: 'test <img src=x onerror=alert(document.domain)>',
        },
      });
    });

    it('capitalizes and escapes name', () => {
      expect(findStageColumnTitle().text()).toBe(
        'Test &lt;img src=x onerror=alert(document.domain)&gt;',
      );
    });

    it('escapes id', () => {
      expect(findStageColumnGroup().attributes('id')).toBe(
        'ci-badge-&lt;img src=x onerror=alert(document.domain)&gt;',
      );
    });
  });

  describe('with action', () => {
    beforeEach(() => {
      createComponent({
        method: mount,
        props: {
          groups: [
            {
              id: 4259,
              name: '<img src=x onerror=alert(document.domain)>',
              status: {
                icon: 'status_success',
                label: 'success',
                tooltip: '<img src=x onerror=alert(document.domain)>',
              },
            },
          ],
          title: 'test',
          hasTriggeredBy: false,
          action: {
            icon: 'play',
            title: 'Play all',
            path: 'action',
          },
        },
      });
    });

    it('renders action button', () => {
      expect(findActionComponent().exists()).toBe(true);
    });
  });

  describe('without action', () => {
    beforeEach(() => {
      createComponent({
        method: mount,
        props: {
          groups: [
            {
              id: 4259,
              name: '<img src=x onerror=alert(document.domain)>',
              status: {
                icon: 'status_success',
                label: 'success',
                tooltip: '<img src=x onerror=alert(document.domain)>',
              },
            },
          ],
          title: 'test',
          hasTriggeredBy: false,
        },
      });
    });

    it('does not render action button', () => {
      expect(findActionComponent().exists()).toBe(false);
    });
  });
});
