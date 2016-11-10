document.addEventListener('todo:toggle', (e) => {
  const todoPendingCount = document.querySelector('.todos-pending-count');
  const count = e.detail.count;

  if (todoPendingCount !== null) {
    todoPendingCount.textContent = gl.text.addDelimiter(count);
  }

  if (count === 0 && !todoPendingCount.classList.contains('hidden')) {
    todoPendingCount.classList.add('hidden');
  } else if (count !== 0 && todoPendingCount.classList.contains('hidden')) {
    todoPendingCount.classList.remove('hidden');
  }
});
