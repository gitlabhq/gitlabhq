import { __ } from '~/locale';

export const todoLabel = (hasTodo) => {
  return hasTodo ? __('Mark as done') : __('Add a to do');
};

export const updateGlobalTodoCount = (additionalTodoCount) => {
  const countContainer = document.querySelector('.js-todos-count');

  if (countContainer === null) return;

  const currentCount = parseInt(countContainer.innerText, 10);

  const todoToggleEvent = new CustomEvent('todo:toggle', {
    detail: {
      count: Math.max(currentCount + additionalTodoCount, 0),
    },
  });

  document.dispatchEvent(todoToggleEvent);
};
