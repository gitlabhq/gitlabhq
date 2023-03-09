import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import CreatedAt from '~/members/components/table/created_at.vue';

describe('CreatedAt', () => {
  // March 15th, 2020
  useFakeDate(2020, 2, 15);

  const date = '2020-03-01T00:00:00.000';
  const formattedDate = 'Mar 01, 2020';

  let wrapper;

  const createComponent = (propsData) => {
    wrapper = mountExtended(CreatedAt, {
      propsData: {
        date,
        ...propsData,
      },
    });
  };

  describe('created at text', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays created at text', () => {
      expect(wrapper.findByText(formattedDate).exists()).toBe(true);
    });
  });

  describe('when `createdBy` prop is provided', () => {
    it('displays a link to the user that created the member', () => {
      createComponent({
        createdBy: {
          name: 'Administrator',
          webUrl: 'https://gitlab.com/root',
        },
      });

      const link = wrapper.findByRole('link', { name: 'Administrator' });

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe('https://gitlab.com/root');
    });
  });
});
