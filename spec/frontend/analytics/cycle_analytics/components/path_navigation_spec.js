import { GlPath, GlSkeletonLoader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import Component from '~/analytics/cycle_analytics/components/path_navigation.vue';
import { transformedProjectStagePathData, selectedStage } from '../mock_data';

describe('Project PathNavigation', () => {
  let wrapper = null;
  let trackingSpy = null;

  const createComponent = (props) => {
    return extendedWrapper(
      mount(Component, {
        propsData: {
          stages: transformedProjectStagePathData,
          selectedStage,
          loading: false,
          ...props,
        },
      }),
    );
  };

  const findPathNavigation = () => {
    return wrapper.findByTestId('gl-path-nav');
  };

  const findPathNavigationItems = () => {
    return findPathNavigation().findAll('li');
  };

  const findPathNavigationTitles = () => {
    return findPathNavigation()
      .findAll('li button')
      .wrappers.map((w) => w.html());
  };

  const clickItemAt = (index) => {
    findPathNavigationItems().at(index).find('button').trigger('click');
  };

  const pathItemContent = () => findPathNavigationItems().wrappers.map(extendedWrapper);
  const firstPopover = () => wrapper.findAllByTestId('stage-item-popover').at(0);

  beforeEach(() => {
    wrapper = createComponent();
    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
  });

  describe('displays correctly', () => {
    it('has the correct props', () => {
      expect(wrapper.findComponent(GlPath).props('items')).toMatchObject(
        transformedProjectStagePathData,
      );
    });

    it('contains all the expected stages', () => {
      const stageContent = findPathNavigationTitles();
      transformedProjectStagePathData.forEach((stage, index) => {
        expect(stageContent[index]).toContain(stage.title);
      });
    });

    describe('loading', () => {
      describe('is false', () => {
        it('displays the gl-path component', () => {
          expect(wrapper.findComponent(GlPath).exists()).toBe(true);
        });

        it('hides the gl-skeleton-loading component', () => {
          expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(false);
        });

        it('renders each stage', () => {
          const result = findPathNavigationTitles();
          expect(result.length).toBe(transformedProjectStagePathData.length);
        });

        it('renders each stage with its median', () => {
          const result = findPathNavigationTitles();
          transformedProjectStagePathData.forEach(({ title, metric }, index) => {
            expect(result[index]).toContain(title);
            expect(result[index]).toContain(metric.toString());
          });
        });

        describe('popovers', () => {
          beforeEach(() => {
            wrapper = createComponent({ stages: transformedProjectStagePathData });
          });

          it('renders popovers for all stages', () => {
            pathItemContent().forEach((stage) => {
              expect(stage.findByTestId('stage-item-popover').exists()).toBe(true);
            });
          });

          it('shows the median stage time for the first stage item', () => {
            expect(firstPopover().text()).toContain('Stage time (median)');
          });

          it('passes correct settings to popover', () => {
            expect(firstPopover().props('placement')).toBe('bottom');
            expect(firstPopover().props('triggers')).toBeUndefined();
          });
        });
      });

      describe('is true', () => {
        beforeEach(() => {
          wrapper = createComponent({ loading: true });
        });

        it('hides the gl-path component', () => {
          expect(wrapper.findComponent(GlPath).exists()).toBe(false);
        });

        it('displays the gl-skeleton-loading component', () => {
          expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
        });
      });
    });
  });

  describe('event handling', () => {
    it('emits the selected event', () => {
      expect(wrapper.emitted('selected')).toBeUndefined();

      clickItemAt(0);
      clickItemAt(1);
      clickItemAt(2);

      expect(wrapper.emitted().selected).toEqual([
        [transformedProjectStagePathData[0]],
        [transformedProjectStagePathData[1]],
        [transformedProjectStagePathData[2]],
      ]);
    });

    it('sends tracking information', () => {
      clickItemAt(0);

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_path_navigation', {
        extra: { stage_id: selectedStage.slug },
      });
    });
  });
});
