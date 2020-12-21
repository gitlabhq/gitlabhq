import { shallowMount } from '@vue/test-utils';
import { withGonExperiment } from 'helpers/experimentation_helper';
import EmptyState from '~/pipelines/components/pipelines_list/empty_state.vue';
import Tracking from '~/tracking';

describe('Pipelines Empty State', () => {
  let wrapper;

  const findGetStartedButton = () => wrapper.find('[data-testid="get-started-pipelines"]');
  const findInfoText = () => wrapper.find('[data-testid="info-text"]').text();
  const createWrapper = () => {
    wrapper = shallowMount(EmptyState, {
      propsData: {
        helpPagePath: 'foo',
        emptyStateSvgPath: 'foo',
        canSetCi: true,
      },
    });
  };

  describe('renders', () => {
    beforeEach(() => {
      createWrapper();
    });

    afterEach(() => {
      wrapper.destroy();
      wrapper = null;
    });

    it('should render empty state SVG', () => {
      expect(wrapper.find('img').attributes('src')).toBe('foo');
    });

    it('should render empty state header', () => {
      expect(wrapper.find('[data-testid="header-text"]').text()).toBe('Build with confidence');
    });

    it('should render a link with provided help path', () => {
      expect(findGetStartedButton().attributes('href')).toBe('foo');
    });

    describe('when in control group', () => {
      it('should render empty state information', () => {
        expect(findInfoText()).toContain(
          'Continuous Integration can help catch bugs by running your tests automatically',
          'while Continuous Deployment can help you deliver code to your product environment',
        );
      });

      it('should render a button', () => {
        expect(findGetStartedButton().text()).toBe('Get started with Pipelines');
      });
    });

    describe('when in experiment group', () => {
      withGonExperiment('pipelinesEmptyState');

      beforeEach(() => {
        createWrapper();
      });

      it('should render empty state information', () => {
        expect(findInfoText()).toContain(
          'GitLab CI/CD can automatically build, test, and deploy your code. Let GitLab take care of time',
          'consuming tasks, so you can spend more time creating',
        );
      });

      it('should render button text', () => {
        expect(findGetStartedButton().text()).toBe('Get started with CI/CD');
      });
    });

    describe('tracking', () => {
      let origGon;

      describe('when data is set', () => {
        beforeEach(() => {
          jest.spyOn(Tracking, 'event').mockImplementation(() => {});
          origGon = window.gon;

          window.gon = {
            tracking_data: {
              category: 'Growth::Activation::Experiment::PipelinesEmptyState',
              value: 1,
              property: 'experimental_group',
              label: 'label',
            },
          };
          createWrapper();
        });

        afterEach(() => {
          window.gon = origGon;
        });

        it('tracks when mounted', () => {
          expect(Tracking.event).toHaveBeenCalledWith(
            'Growth::Activation::Experiment::PipelinesEmptyState',
            'viewed',
            {
              value: 1,
              label: 'label',
              property: 'experimental_group',
            },
          );
        });

        it('tracks when button is clicked', () => {
          findGetStartedButton().vm.$emit('click');

          expect(Tracking.event).toHaveBeenCalledWith(
            'Growth::Activation::Experiment::PipelinesEmptyState',
            'documentation_clicked',
            {
              value: 1,
              label: 'label',
              property: 'experimental_group',
            },
          );
        });
      });

      describe('when no data is defined', () => {
        beforeEach(() => {
          jest.spyOn(Tracking, 'event').mockImplementation(() => {});

          createWrapper();
        });

        it('does not track on view', () => {
          expect(Tracking.event).not.toHaveBeenCalled();
        });

        it('does not track when button is clicked', () => {
          findGetStartedButton().vm.$emit('click');
          expect(Tracking.event).not.toHaveBeenCalled();
        });
      });
    });
  });
});
