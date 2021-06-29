import { shallowMount } from '@vue/test-utils';
import App from '~/pages/projects/new/components/app.vue';
import NewNamespacePage from '~/vue_shared/new_namespace/new_namespace_page.vue';

describe('Experimental new project creation app', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = shallowMount(App, { propsData });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('passes custom new project guideline text to underlying component', () => {
    const DEMO_GUIDELINES = 'Demo guidelines';
    const guidelineSelector = '#new-project-guideline';
    createComponent({
      newProjectGuidelines: DEMO_GUIDELINES,
    });

    expect(wrapper.find(guidelineSelector).text()).toBe(DEMO_GUIDELINES);
  });

  it.each`
    isCiCdAvailable | outcome
    ${false}        | ${'do not show CI/CD panel'}
    ${true}         | ${'show CI/CD panel'}
  `('$outcome when isCiCdAvailable is $isCiCdAvailable', ({ isCiCdAvailable }) => {
    createComponent({
      isCiCdAvailable,
    });

    expect(
      Boolean(
        wrapper
          .findComponent(NewNamespacePage)
          .props()
          .panels.find((p) => p.name === 'cicd_for_external_repo'),
      ),
    ).toBe(isCiCdAvailable);
  });
});
