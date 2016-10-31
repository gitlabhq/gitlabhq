document.addEventListener('todo:toggle', (event) => {
  const todoPendingCount = document.querySelector('.todos-pending-count');
  const count = event.detail.count;

  if (todoPendingCount !== null) {
    todoPendingCount.textContent = gl.text.addDelimiter(count);
  }

  if (count === 0 && !todoPendingCount.classList.contains('hidden')) {
    todoPendingCount.classList.add('hidden');
  } else if (count !== 0 && todoPendingCount.classList.contains('hidden')) {
    todoPendingCount.classList.remove('hidden');
  }
});
