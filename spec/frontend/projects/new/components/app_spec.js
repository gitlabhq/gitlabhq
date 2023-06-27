import { shallowMount } from '@vue/test-utils';
import App from '~/projects/new/components/app.vue';
import NewNamespacePage from '~/vue_shared/new_namespace/new_namespace_page.vue';

describe('Experimental new project creation app', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = shallowMount(App, {
      propsData: { rootPath: '/', projectsUrl: '/dashboard/projects', ...propsData },
    });
  };

  const findNewNamespacePage = () => wrapper.findComponent(NewNamespacePage);

  it('passes custom new project guideline text to underlying component', () => {
    const DEMO_GUIDELINES = 'Demo guidelines';
    const guidelineSelector = '#new-project-guideline';
    createComponent({
      newProjectGuidelines: DEMO_GUIDELINES,
    });

    expect(wrapper.find(guidelineSelector).text()).toBe(DEMO_GUIDELINES);
  });

  it('creates correct panels', () => {
    createComponent();

    expect(findNewNamespacePage().props('panels')).toMatchSnapshot();
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
        findNewNamespacePage()
          .props()
          .panels.find((p) => p.name === 'cicd_for_external_repo'),
      ),
    ).toBe(isCiCdAvailable);
  });

  it.each`
    canImportProjects | outcome
    ${false}          | ${'do not show Import panel'}
    ${true}           | ${'show Import panel'}
  `('$outcome when canImportProjects is $canImportProjects', ({ canImportProjects }) => {
    createComponent({
      canImportProjects,
    });

    expect(
      findNewNamespacePage()
        .props()
        .panels.some((p) => p.name === 'import_project'),
    ).toBe(canImportProjects);
  });

  it('creates correct breadcrumbs for top-level projects', () => {
    createComponent();

    expect(findNewNamespacePage().props('initialBreadcrumbs')).toEqual([
      { href: '/', text: 'Your work' },
      { href: '/dashboard/projects', text: 'Projects' },
      { href: '#', text: 'New project' },
    ]);
  });

  it('creates correct breadcrumbs for projects within groups', () => {
    createComponent({ parentGroupUrl: '/parent-group', parentGroupName: 'Parent Group' });

    expect(findNewNamespacePage().props('initialBreadcrumbs')).toEqual([
      { href: '/parent-group', text: 'Parent Group' },
      { href: '#', text: 'New project' },
    ]);
  });
});
