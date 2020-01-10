import { mount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import { getTimeago } from '~/lib/utils/datetime_utility';
import ErasedBlock from '~/jobs/components/erased_block.vue';

describe('Erased block', () => {
  let wrapper;

  const erasedAt = '2016-11-07T11:11:16.525Z';
  const timeago = getTimeago();
  const formattedDate = timeago.format(erasedAt);

  const createComponent = props => {
    wrapper = mount(ErasedBlock, {
      propsData: props,
      attachToDocument: true,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with job erased by user', () => {
    beforeEach(() => {
      createComponent({
        user: {
          username: 'root',
          web_url: 'gitlab.com/root',
        },
        erasedAt,
      });
    });

    it('renders username and link', () => {
      expect(wrapper.find(GlLink).attributes('href')).toEqual('gitlab.com/root');

      expect(wrapper.text().trim()).toContain('Job has been erased by');
      expect(wrapper.text().trim()).toContain('root');
    });

    it('renders erasedAt', () => {
      expect(wrapper.text().trim()).toContain(formattedDate);
    });
  });

  describe('with erased job', () => {
    beforeEach(() => {
      createComponent({
        erasedAt,
      });
    });

    it('renders username and link', () => {
      expect(wrapper.text().trim()).toContain('Job has been erased');
    });

    it('renders erasedAt', () => {
      expect(wrapper.text().trim()).toContain(formattedDate);
    });
  });
});
