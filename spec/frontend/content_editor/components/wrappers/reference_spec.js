import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReferenceWrapper from '~/content_editor/components/wrappers/reference.vue';

describe('content/components/wrappers/reference', () => {
  let wrapper;

  const createWrapper = async (node = {}) => {
    wrapper = shallowMountExtended(ReferenceWrapper, {
      propsData: { node },
    });
  };

  it('renders a span for comamnds', () => {
    createWrapper({ attrs: { referenceType: 'command', text: '/assign' } });

    expect(wrapper.html()).toMatchInlineSnapshot(
      `"<node-view-wrapper-stub as=\\"div\\" class=\\"gl-display-inline-block\\"><span>/assign</span></node-view-wrapper-stub>"`,
    );
  });

  it('renders an anchor for everything else', () => {
    createWrapper({ attrs: { referenceType: 'issue', text: '#252522' } });

    expect(wrapper.html()).toMatchInlineSnapshot(
      `"<node-view-wrapper-stub as=\\"div\\" class=\\"gl-display-inline-block\\"><a href=\\"#\\">#252522</a></node-view-wrapper-stub>"`,
    );
  });
});
