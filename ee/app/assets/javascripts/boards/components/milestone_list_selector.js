import BoardsListSelector from './boards_list_selector';

export default function () {
  const $addListEl = document.querySelector('#js-add-list');
  return new BoardsListSelector({
    propsData: {
      listPath: $addListEl.querySelector('.js-new-board-list').dataset.listMilestonePath,
      listType: 'milestones',
    },
  }).$mount('.js-milestone-list');
}
