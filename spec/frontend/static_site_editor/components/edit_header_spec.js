import { shallowMount } from '@vue/test-utils';

import EditHeader from '~/static_site_editor/components/edit_header.vue';
import { DEFAULT_HEADING } from '~/static_site_editor/constants';

import { sourceContentTitle } from '../mock_data';

describe('~/static_site_editor/components/edit_header.vue', () => {
  let wrapper;

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(EditHeader, {
      propsData: {
        ...propsData,
      },
    });
  };

  const findHeading = () => wrapper.find({ ref: 'sseHeading' });

  beforeEach(() => {
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the default heading if there is no title prop', () => {
    expect(findHeading().text()).toBe(DEFAULT_HEADING);
  });

  it('renders the title prop value in the heading', () => {
    buildWrapper({ title: sourceContentTitle });

    expect(findHeading().text()).toBe(sourceContentTitle);
  });
});
