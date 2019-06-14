const debounce = (fn, time) => {
  let current;

  const debounced = () => {
    if (current) {
      clearTimeout(current);
    }

    current = setTimeout(fn, time);
  };

  return debounced;
};

export default debounce;
