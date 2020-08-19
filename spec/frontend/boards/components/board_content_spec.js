import { mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import BoardContent from '~/boards/components/board_content.vue';
import BoardColumn from '~/boards/components/board_column.vue';
import List from '~/boards/models/list';
import { listObj } from '../mock_data';

describe('BoardContent', () => {
  let wrapper;
  let mock;

  const createComponent = () => {
    wrapper = mount(BoardContent, {
      propsData: {
        lists: [new List(listObj)],
        canAdminList: true,
        groupId: 1,
        disabled: false,
        issueLinkBase: '',
        rootPath: '',
        boardId: '',
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('finds BoardColumns', () => {
    createComponent();

    expect(wrapper.findAll(BoardColumn).length).toBe(1);
  });
});
