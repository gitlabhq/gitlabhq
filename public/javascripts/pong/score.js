class Score {
  constructor(element) {
    this.element = element;
    this.points = parseInt(element.innerText);
  }

  start() {
    this.points = Math.floor(this.points * 0.925);

    this.element.innerText = this.points;

    return this.points === 0;
  }
}

export default Score;
