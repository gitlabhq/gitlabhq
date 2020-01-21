import Vue from 'vue';
import navControlsComp from '~/pipelines/components/nav_controls.vue';
import mountComponent from '../helpers/vue_mount_component_helper';

describe('Pipelines Nav Controls', () => {
  let NavControlsComponent;
  let component;

  beforeEach(() => {
    NavControlsComponent = Vue.extend(navControlsComp);
  });

  afterEach(() => {
    component.$destroy();
  });

  it('should render link to create a new pipeline', () => {
    const mockData = {
      newPipelinePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
    };

    component = mountComponent(NavControlsComponent, mockData);

    expect(component.$el.querySelector('.js-run-pipeline').textContent).toContain('Run Pipeline');
    expect(component.$el.querySelector('.js-run-pipeline').getAttribute('href')).toEqual(
      mockData.newPipelinePath,
    );
  });

  it('should not render link to create pipeline if no path is provided', () => {
    const mockData = {
      helpPagePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
    };

    component = mountComponent(NavControlsComponent, mockData);

    expect(component.$el.querySelector('.js-run-pipeline')).toEqual(null);
  });

  it('should render link for CI lint', () => {
    const mockData = {
      newPipelinePath: 'foo',
      helpPagePath: 'foo',
      ciLintPath: 'foo',
      resetCachePath: 'foo',
    };

    component = mountComponent(NavControlsComponent, mockData);

    expect(component.$el.querySelector('.js-ci-lint').textContent.trim()).toContain('CI Lint');
    expect(component.$el.querySelector('.js-ci-lint').getAttribute('href')).toEqual(
      mockData.ciLintPath,
    );
  });

  describe('Reset Runners Cache', () => {
    beforeEach(() => {
      const mockData = {
        newPipelinePath: 'foo',
        ciLintPath: 'foo',
        resetCachePath: 'foo',
      };

      component = mountComponent(NavControlsComponent, mockData);
    });

    it('should render button for resetting runner caches', () => {
      expect(component.$el.querySelector('.js-clear-cache').textContent.trim()).toContain(
        'Clear Runner Caches',
      );
    });

    it('should emit postAction event when reset runner cache button is clicked', () => {
      jest.spyOn(component, '$emit').mockImplementation(() => {});

      component.$el.querySelector('.js-clear-cache').click();

      expect(component.$emit).toHaveBeenCalledWith('resetRunnersCache', 'foo');
    });
  });
});
