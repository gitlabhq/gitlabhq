import { shallowMount } from '@vue/test-utils';
import LoadingStateList from '~/vue_shared/components/resource_lists/loading_state_list.vue';
import LoadingStateListItem from '~/vue_shared/components/resource_lists/loading_state_list_item.vue';

describe('LoadingStateList', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(LoadingStateList, {
      propsData: props,
    });
  };

  const findListItems = () => wrapper.findAll('li');
  const findLoadingStateListItems = () => wrapper.findAllComponents(LoadingStateListItem);

  describe('when no props are provided', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the correct number of list items', () => {
      expect(findListItems()).toHaveLength(5);
    });

    it('passes the correct number of leftLinesCount to LoadingStateListItem', () => {
      findLoadingStateListItems().wrappers.forEach((item) => {
        expect(item.props('leftLinesCount')).toBe(2);
      });
    });

    it('passes the correct number of rightLinesCount to LoadingStateListItem', () => {
      findLoadingStateListItems().wrappers.forEach((item) => {
        expect(item.props('rightLinesCount')).toBe(2);
      });
    });
  });

  describe('when props are provided', () => {
    const listLength = 10;
    const leftLinesCount = 3;
    const rightLinesCount = 4;

    beforeEach(() => {
      createWrapper({
        listLength,
        leftLinesCount,
        rightLinesCount,
      });
    });

    it('renders the correct number of list items', () => {
      expect(findListItems()).toHaveLength(listLength);
    });

    it('passes the correct number of leftLinesCount to LoadingStateListItem', () => {
      findLoadingStateListItems().wrappers.forEach((item) => {
        expect(item.props('leftLinesCount')).toBe(leftLinesCount);
      });
    });

    it('passes the correct number of rightLinesCount to LoadingStateListItem', () => {
      findLoadingStateListItems().wrappers.forEach((item) => {
        expect(item.props('rightLinesCount')).toBe(rightLinesCount);
      });
    });
  });
});
