require 'spec_helper'

describe Ansi2html do

  it "prints non-ansi as-is" do
    Ansi2html::convert("Hello").should == 'Hello'
  end

  it "strips non-color-changing controll sequences" do
    Ansi2html::convert("Hello \e[2Kworld").should == 'Hello world'
  end

  it "prints simply red" do
    Ansi2html::convert("\e[31mHello\e[0m").should == '<span class="term-fg-red">Hello</span>'
  end

  it "prints simply red without trailing reset" do
    Ansi2html::convert("\e[31mHello").should == '<span class="term-fg-red">Hello</span>'
  end

  it "prints simply yellow" do
    Ansi2html::convert("\e[33mHello\e[0m").should == '<span class="term-fg-yellow">Hello</span>'
  end

  it "prints default on blue" do
    Ansi2html::convert("\e[39;44mHello").should == '<span class="term-bg-blue">Hello</span>'
  end

  it "prints red on blue" do
    Ansi2html::convert("\e[31;44mHello").should == '<span class="term-fg-red term-bg-blue">Hello</span>'
  end

  it "resets colors after red on blue" do
    Ansi2html::convert("\e[31;44mHello\e[0m world").should == '<span class="term-fg-red term-bg-blue">Hello</span> world'
  end

  it "performs color change from red/blue to yellow/blue" do
    Ansi2html::convert("\e[31;44mHello \e[33mworld").should == '<span class="term-fg-red term-bg-blue">Hello </span><span class="term-fg-yellow term-bg-blue">world</span>'
  end

  it "performs color change from red/blue to yellow/green" do
    Ansi2html::convert("\e[31;44mHello \e[33;42mworld").should == '<span class="term-fg-red term-bg-blue">Hello </span><span class="term-fg-yellow term-bg-green">world</span>'
  end

  it "performs color change from red/blue to reset to yellow/green" do
    Ansi2html::convert("\e[31;44mHello\e[0m \e[33;42mworld").should == '<span class="term-fg-red term-bg-blue">Hello</span> <span class="term-fg-yellow term-bg-green">world</span>'
  end

  it "ignores unsupported codes" do
    Ansi2html::convert("\e[51mHello\e[0m").should == 'Hello'
  end

  it "prints light red" do
    Ansi2html::convert("\e[91mHello\e[0m").should == '<span class="term-fg-l-red">Hello</span>'
  end

  it "prints default on light red" do
    Ansi2html::convert("\e[101mHello\e[0m").should == '<span class="term-bg-l-red">Hello</span>'
  end

  it "performs color change from red/blue to default/blue" do
    Ansi2html::convert("\e[31;44mHello \e[39mworld").should == '<span class="term-fg-red term-bg-blue">Hello </span><span class="term-bg-blue">world</span>'
  end

  it "performs color change from light red/blue to default/blue" do
    Ansi2html::convert("\e[91;44mHello \e[39mworld").should == '<span class="term-fg-l-red term-bg-blue">Hello </span><span class="term-bg-blue">world</span>'
  end

  it "prints bold text" do
    Ansi2html::convert("\e[1mHello").should == '<span class="term-bold">Hello</span>'
  end

  it "resets bold text" do
    Ansi2html::convert("\e[1mHello\e[21m world").should == '<span class="term-bold">Hello</span> world'
    Ansi2html::convert("\e[1mHello\e[22m world").should == '<span class="term-bold">Hello</span> world'
  end

  it "prints italic text" do
    Ansi2html::convert("\e[3mHello").should == '<span class="term-italic">Hello</span>'
  end

  it "resets italic text" do
    Ansi2html::convert("\e[3mHello\e[23m world").should == '<span class="term-italic">Hello</span> world'
  end

  it "prints underlined text" do
    Ansi2html::convert("\e[4mHello").should == '<span class="term-underline">Hello</span>'
  end

  it "resets underlined text" do
    Ansi2html::convert("\e[4mHello\e[24m world").should == '<span class="term-underline">Hello</span> world'
  end

  it "prints concealed text" do
    Ansi2html::convert("\e[8mHello").should == '<span class="term-conceal">Hello</span>'
  end

  it "resets concealed text" do
    Ansi2html::convert("\e[8mHello\e[28m world").should == '<span class="term-conceal">Hello</span> world'
  end

  it "prints crossed-out text" do
    Ansi2html::convert("\e[9mHello").should == '<span class="term-cross">Hello</span>'
  end

  it "resets crossed-out text" do
    Ansi2html::convert("\e[9mHello\e[29m world").should == '<span class="term-cross">Hello</span> world'
  end

  it "can print 256 xterm fg colors" do
    Ansi2html::convert("\e[38;5;16mHello").should == '<span class="xterm-fg-16">Hello</span>'
  end

  it "can print 256 xterm fg colors on normal magenta background" do
    Ansi2html::convert("\e[38;5;16;45mHello").should == '<span class="xterm-fg-16 term-bg-magenta">Hello</span>'
  end

  it "can print 256 xterm bg colors" do
    Ansi2html::convert("\e[48;5;240mHello").should == '<span class="xterm-bg-240">Hello</span>'
  end

  it "can print 256 xterm bg colors on normal magenta foreground" do
    Ansi2html::convert("\e[48;5;16;35mHello").should == '<span class="term-fg-magenta xterm-bg-16">Hello</span>'
  end

  it "prints bold colored text vividly" do
    Ansi2html::convert("\e[1;31mHello\e[0m").should == '<span class="term-fg-l-red term-bold">Hello</span>'
  end

  it "prints bold light colored text correctly" do
    Ansi2html::convert("\e[1;91mHello\e[0m").should == '<span class="term-fg-l-red term-bold">Hello</span>'
  end
end
