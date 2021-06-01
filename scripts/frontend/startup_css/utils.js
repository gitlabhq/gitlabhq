const die = (message) => {
  console.log(message);
  process.exit(1);
};

const log = (message) => console.error(`[gitlab.startup_css] ${message}`);

module.exports = { die, log };
