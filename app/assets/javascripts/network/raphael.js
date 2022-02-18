import Raphael from 'raphael/raphael';
import { formatDate } from '~/lib/utils/datetime_utility';

Raphael.prototype.commitTooltip = function commitTooltip(x, y, commit) {
  const boxWidth = 300;
  const icon = this.image(gon.relative_url_root + commit.author.icon, x, y, 20, 20);
  const nameText = this.text(x + 25, y + 10, commit.author.name);
  const dateText = this.text(x, y + 35, formatDate(commit.date));
  const idText = this.text(x, y + 55, commit.id);
  const messageText = this.text(x, y + 70, commit.message.replace(/\r?\n/g, ' \n '));
  const textSet = this.set(icon, nameText, dateText, idText, messageText).attr({
    'text-anchor': 'start',
    font: '12px Monaco, monospace',
  });
  nameText.attr({
    font: '14px Arial',
    'font-weight': 'bold',
  });
  dateText.attr({
    fill: '#666',
  });
  idText.attr({
    fill: '#AAA',
  });
  messageText.node.style['white-space'] = 'pre';
  this.textWrap(messageText, boxWidth - 50);
  const rect = this.rect(x - 10, y - 10, boxWidth, 100, 4).attr({
    fill: '#FFF',
    stroke: '#000',
    'stroke-linecap': 'round',
    'stroke-width': 2,
  });
  const tooltip = this.set(rect, textSet);
  rect.attr({
    height: tooltip.getBBox().height + 10,
    width: tooltip.getBBox().width + 10,
  });
  tooltip.transform(['t', 20, 20]);
  return tooltip;
};

Raphael.prototype.textWrap = function testWrap(t, width) {
  const content = t.attr('text');
  const abc = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  t.attr({
    text: abc,
  });
  const letterWidth = t.getBBox().width / abc.length;
  t.attr({
    text: content,
  });
  const words = content.split(' ');
  let x = 0;
  const s = [];
  for (let j = 0, len = words.length; j < len; j += 1) {
    const word = words[j];
    if (x + word.length * letterWidth > width) {
      s.push('\n');
      x = 0;
    }
    if (word === '\n') {
      s.push('\n');
      x = 0;
    } else {
      s.push(`${word} `);
      x += word.length * letterWidth;
    }
  }
  t.attr({
    text: s.join('').trim(),
  });
  const b = t.getBBox();
  const h = Math.abs(b.y2) + 1;
  return t.attr({
    y: h,
  });
};

export default Raphael;
