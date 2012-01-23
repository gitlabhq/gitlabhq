var commits = {},
    comms = {},
    pixelsX = [],
    pixelsY = [],
    mmax = Math.max,
    mtime = 0,
    mspace = 0,
    parents = {},
    ii = 0,
    colors = ["#000"];

function initGraph(){
  commits = chunk1.commits;
  ii = commits.length;
  for (var i = 0; i < ii; i++) {
      for (var j = 0, jj = commits[i].parents.length; j < jj; j++) {
          parents[commits[i].parents[j][0]] = true;
      }
      mtime = Math.max(mtime, commits[i].time);
      mspace = Math.max(mspace, commits[i].space);
  }
  mtime = mtime + 4;
  mspace = mspace + 10;
  for (i = 0; i < ii; i++) {
      if (commits[i].id in parents) {
          commits[i].isParent = true;
      }
      comms[commits[i].id] = commits[i];
  }
  for (var k = 0; k < mspace; k++) {
      colors.push(Raphael.getColor());
  }
}

function branchGraph(holder) {
    var ch = mspace * 20 + 20, cw = mtime * 20 + 20,
        r = Raphael("holder", cw, ch),
        top = r.set();
    var cuday = 0, cumonth = "";
    r.rect(0, 0, days.length * 20 + 20, 20).attr({fill: "#474D57"});
    r.rect(0, 20, days.length * 20 + 20, 20).attr({fill: "#f7f7f7"});

    for (mm = 0; mm < days.length; mm++) {
        if(days[mm] != null){
            if(cuday != days[mm][0]){
                r.text(10 + mm * 20, 30, days[mm][0]).attr({font: "12px Fontin-Sans, Arial", fill: "#444"});
                cuday = days[mm][0]
            }
            if(cumonth != days[mm][1]){
                r.text(10 + mm * 20, 10, days[mm][1]).attr({font: "12px Fontin-Sans, Arial", fill: "#444"});
                cumonth = days[mm][1]
            }

        }
    }
    for (i = 0; i < ii; i++) {
        var x = 10 + 20 * commits[i].time,
            y = 70 + 20 * commits[i].space;
        r.circle(x, y, 3).attr({fill: colors[commits[i].space], stroke: "none"});
        if (commits[i].refs != null && commits[i].refs != "") {
            var longrefs = commits[i].refs
            var shortrefs = commits[i].refs;
            if (shortrefs.length > 15){
              shortrefs = shortrefs.substr(0,13) + "...";
            }
            var t = r.text(x+5, y+5, shortrefs).attr({font: "12px Fontin-Sans, Arial", fill: "#666",
            title: longrefs, cursor: "pointer", rotation: "90"});

            var textbox = t.getBBox();
            t.translate(textbox.height/-4,textbox.width/2);
        }
        for (var j = 0, jj = commits[i].parents.length; j < jj; j++) {
            var c = comms[commits[i].parents[j][0]];
            if (c) {
                var cx = 10 + 20 * c.time,
                    cy = 70 + 20 * c.space;
                if (c.space == commits[i].space) {
                    r.path("M" + (x - 5) + "," + (y + .0001) + "L" + (15 + 20 * c.time) + "," + (y + .0001))
                    .attr({stroke: colors[c.space], "stroke-width": 2});

                } else if (c.space < commits[i].space) {
                    r.path(["M", x - 5, y + .0001, "l-5-2,0,4,5,-2C",x-5,y,x -17, y+2, x -20, y-10,"L", cx,y-10,cx , cy])
                    .attr({stroke: colors[commits[i].space], "stroke-width": 2});
                } else {
                    r.path(["M", x-5, y, "l-5-2,0,4,5,-2C",x-5,y,x -17, y-2, x -20, y+10,"L", cx,y+10,cx , cy])
                    .attr({stroke: colors[commits[i].space], "stroke-width": 2});
                }
            }
        }
        (function (c, x, y) {
            top.push(r.circle(x, y, 10).attr({fill: "#000", opacity: 0, cursor: "pointer"})
            .click(function(){
              location.href = location.href.replace("graph", "commits/" + c.id);
            })
            .hover(function () {
                var s = r.text(100, 100,c.author + "\n \n" +c.id + "\n \n" + c.message).attr({fill: "#fff"});
                this.popup = r.popupit(x, y + 5, s, 0);
                top.push(this.popup.insertBefore(this));
            }, function () {
                this.popup && this.popup.remove() && delete this.popup;
            }));
        }(commits[i], x, y));
    }
    top.toFront();
    var hw = holder.offsetWidth,
        hh = holder.offsetHeight,
        v = r.rect(hw - 8, 0, 4, Math.pow(hh, 2) / ch, 2).attr({fill: "#000", opacity: 0}),
        h = r.rect(0, hh - 8, Math.pow(hw, 2) / cw, 4, 2).attr({fill: "#000", opacity: 0}),
        bars = r.set(v, h),
        drag,
        dragger = function (e) {
            if (drag) {
                e = e || window.event;
                holder.scrollLeft = drag.sl - (e.clientX - drag.x);
                holder.scrollTop = drag.st - (e.clientY - drag.y);
            }
        };
    holder.onmousedown = function (e) {
        e = e || window.event;
        drag = {x: e.clientX, y: e.clientY, st: holder.scrollTop, sl: holder.scrollLeft};
        document.onmousemove = dragger;
        bars.animate({opacity: .5}, 300);
    };
    document.onmouseup = function () {
        drag = false;
        document.onmousemove = null;
        bars.animate({opacity: 0}, 300);
    };
    holder.scrollLeft = cw;
};
Raphael.fn.popupit = function (x, y, set, dir, size) {
    dir = dir == null ? 2 : dir;
    size = size || 5;
    x = Math.round(x);
    y = Math.round(y);
    var bb = set.getBBox(),
        w = Math.round(bb.width / 2),
        h = Math.round(bb.height / 2),
        dx = [0, w + size * 2, 0, -w - size * 2],
        dy = [-h * 2 - size * 3, -h - size, 0, -h - size],
        p = ["M", x - dx[dir], y - dy[dir], "l", -size, (dir == 2) * -size, -mmax(w - size, 0), 0, "a", size, size, 0, 0, 1, -size, -size,
            "l", 0, -mmax(h - size, 0), (dir == 3) * -size, -size, (dir == 3) * size, -size, 0, -mmax(h - size, 0), "a", size, size, 0, 0, 1, size, -size,
            "l", mmax(w - size, 0), 0, size, !dir * -size, size, !dir * size, mmax(w - size, 0), 0, "a", size, size, 0, 0, 1, size, size,
            "l", 0, mmax(h - size, 0), (dir == 1) * size, size, (dir == 1) * -size, size, 0, mmax(h - size, 0), "a", size, size, 0, 0, 1, -size, size,
            "l", -mmax(w - size, 0), 0, "z"].join(","),
        xy = [{x: x, y: y + size * 2 + h}, {x: x - size * 2 - w, y: y}, {x: x, y: y - size * 2 - h}, {x: x + size * 2 + w, y: y}][dir];
    set.translate(xy.x - w - bb.x, xy.y - h - bb.y);
    return this.set(this.path(p).attr({fill: "#234", stroke: "none"}).insertBefore(set.node ? set : set[0]), set);
};
Raphael.fn.popup = function (x, y, text, dir, size) {
    dir = dir == null ? 2 : dir > 3 ? 3 : dir;
    size = size || 5;
    text = text || "$9.99";
    var res = this.set(),
        d = 3;
    res.push(this.path().attr({fill: "#000", stroke: "#000"}));
    res.push(this.text(x, y, text).attr(this.g.txtattr).attr({fill: "#fff", "font-family": "Helvetica, Arial"}));
    res.update = function (X, Y, withAnimation) {
        X = X || x;
        Y = Y || y;
        var bb = this[1].getBBox(),
            w = bb.width / 2,
            h = bb.height / 2,
            dx = [0, w + size * 2, 0, -w - size * 2],
            dy = [-h * 2 - size * 3, -h - size, 0, -h - size],
            p = ["M", X - dx[dir], Y - dy[dir], "l", -size, (dir == 2) * -size, -mmax(w - size, 0), 0, "a", size, size, 0, 0, 1, -size, -size,
                "l", 0, -mmax(h - size, 0), (dir == 3) * -size, -size, (dir == 3) * size, -size, 0, -mmax(h - size, 0), "a", size, size, 0, 0, 1, size, -size,
                "l", mmax(w - size, 0), 0, size, !dir * -size, size, !dir * size, mmax(w - size, 0), 0, "a", size, size, 0, 0, 1, size, size,
                "l", 0, mmax(h - size, 0), (dir == 1) * size, size, (dir == 1) * -size, size, 0, mmax(h - size, 0), "a", size, size, 0, 0, 1, -size, size,
                "l", -mmax(w - size, 0), 0, "z"].join(","),
            xy = [{x: X, y: Y + size * 2 + h}, {x: X - size * 2 - w, y: Y}, {x: X, y: Y - size * 2 - h}, {x: X + size * 2 + w, y: Y}][dir];
        xy.path = p;
        if (withAnimation) {
            this.animate(xy, 500, ">");
        } else {
            this.attr(xy);
        }
        return this;
    };
    return res.update(x, y);
};
