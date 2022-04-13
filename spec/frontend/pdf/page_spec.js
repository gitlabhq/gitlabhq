import Vue, { nextTick } from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import PageComponent from '~/pdf/page/index.vue';

jest.mock('pdfjs-dist/webpack', () => {
  return { default: jest.requireActual('pdfjs-dist/build/pdf') };
});

describe('Page component', () => {
  const Component = Vue.extend(PageComponent);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the page when mounting', async () => {
    const testPage = {
      render: jest.fn().mockReturnValue({ promise: Promise.resolve() }),
      getViewport: jest.fn().mockReturnValue({}),
    };

    vm = mountComponent(Component, {
      page: testPage,
      number: 1,
    });

    expect(vm.rendering).toBe(true);

    await nextTick();

    expect(testPage.render).toHaveBeenCalledWith(vm.renderContext);
    expect(vm.rendering).toBe(false);
  });
});
