import { mount } from '@vue/test-utils';
import EmptyState from '~/jobs/components/empty_state.vue';

describe('Empty State', () => {
  let wrapper;

  const defaultProps = {
    illustrationPath: 'illustrations/pending_job_empty.svg',
    illustrationSizeClass: 'svg-430',
    title: 'This job has not started yet',
    playable: false,
  };

  const createWrapper = (props) => {
    wrapper = mount(EmptyState, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const content = 'This job is in pending state and is waiting to be picked by a runner';

  const findEmptyStateImage = () => wrapper.find('img');
  const findTitle = () => wrapper.find('[data-testid="job-empty-state-title"]');
  const findContent = () => wrapper.find('[data-testid="job-empty-state-content"]');
  const findAction = () => wrapper.find('[data-testid="job-empty-state-action"]');
  const findManualVarsForm = () => wrapper.find('[data-testid="manual-vars-form"]');

  afterEach(() => {
    if (wrapper?.destroy) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('renders image and title', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders empty state image', () => {
      expect(findEmptyStateImage().exists()).toBe(true);
    });

    it('renders provided title', () => {
      expect(findTitle().text().trim()).toBe(defaultProps.title);
    });
  });

  describe('with content', () => {
    beforeEach(() => {
      createWrapper({ content });
    });

    it('renders content', () => {
      expect(findContent().text().trim()).toBe(content);
    });
  });

  describe('without content', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not render content', () => {
      expect(findContent().exists()).toBe(false);
    });
  });

  describe('with action', () => {
    beforeEach(() => {
      createWrapper({
        action: {
          path: 'runner',
          button_title: 'Check runner',
          method: 'post',
        },
      });
    });

    it('renders action', () => {
      expect(findAction().attributes('href')).toBe('runner');
    });
  });

  describe('without action', () => {
    beforeEach(() => {
      createWrapper({
        action: null,
      });
    });

    it('does not render action', () => {
      expect(findAction().exists()).toBe(false);
    });

    it('does not render manual variables form', () => {
      expect(findManualVarsForm().exists()).toBe(false);
    });
  });

  describe('with playable action and not scheduled job', () => {
    beforeEach(() => {
      createWrapper({
        content,
        playable: true,
        scheduled: false,
        action: {
          path: 'runner',
          button_title: 'Check runner',
          method: 'post',
        },
      });
    });

    it('renders manual variables form', () => {
      expect(findManualVarsForm().exists()).toBe(true);
    });

    it('does not render the empty state action', () => {
      expect(findAction().exists()).toBe(false);
    });
  });

  describe('with playable action and scheduled job', () => {
    beforeEach(() => {
      createWrapper({
        playable: true,
        scheduled: true,
        content,
      });
    });

    it('does not render manual variables form', () => {
      expect(findManualVarsForm().exists()).toBe(false);
    });
  });
});
