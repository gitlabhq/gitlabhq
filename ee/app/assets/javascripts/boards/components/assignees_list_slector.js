import BoardsListSelector from './boards_list_selector/index';

export default function () {
  const $addListEl = document.querySelector('#js-add-list');
  return new BoardsListSelector({
    propsData: {
      listPath: $addListEl.querySelector('.js-new-board-list').dataset.listAssigneesPath,
      listType: 'assignees',
    },
  }).$mount('.js-assignees-list');
}
