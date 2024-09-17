import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TextPresenter from '~/glql/components/presenters/text.vue';

describe('TextPresenter', () => {
  it.each`
    dataType    | data
    ${'String'} | ${'Hello, world!'}
    ${'Number'} | ${100}
  `('for data type $dataType, it renders the text', ({ data }) => {
    const wrapper = shallowMountExtended(TextPresenter, { propsData: { data } });

    expect(wrapper.text()).toBe(data.toString());
  });

  describe.each`
    dataType       | data
    ${'Null'}      | ${null}
    ${'Undefined'} | ${undefined}
    ${'Object'}    | ${{ some: 'object' }}
    ${'Array'}     | ${[1, 2, 3]}
  `('for data type $dataType', ({ dataType, data }) => {
    beforeEach(() => {
      jest.spyOn(console, 'error').mockImplementation(() => {});
    });

    it('shows a warning in console for mismatched propType', () => {
      shallowMountExtended(TextPresenter, { propsData: { data } });

      // eslint-disable-next-line no-console
      expect(console.error.mock.calls[0][0]).toContain(
        `[Vue warn]: Invalid prop: type check failed for prop "data". Expected String, Number, got ${dataType}`,
      );
    });
  });
});
